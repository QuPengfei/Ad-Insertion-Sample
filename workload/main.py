#!/usr/bin/python3

import socket
import datetime
import psutil
import time
import sys
from messaging import Consumer
import json
import ast
import os.path

LOG_CLEAR_FLAG="/var/www/logs/clear"

kafka_topics=["workload_data"]

info_template = {
    "time": 0,
#    "machine": "",
    "cpu": 0,
    "mem": {},
    "net": {},
    "e2e": {},
    "seg": {},
    "ad": [],
}

playback_info_template={}
analytic_info_template={}
adrate_info_template={"ad_request_tot":0,"ad_request_suc":0,"ad_request_tot_pre":0,"ad_request_suc_pre":0}

def clear_log():
    clear_flag='0'
    if os.path.isfile(LOG_CLEAR_FLAG) == False: return clear_flag 
    with open(LOG_CLEAR_FLAG,"r") as f:
       clear_flag=f.read().strip()
    return clear_flag

def mem():
    #mem = psutil.virtual_memory()
    mem_total = int(psutil.virtual_memory()[0]/1024/1024/1024)
    mem_used = float(format(float(psutil.virtual_memory()[3])/1024/1024/1024,'.2f'))
    mem_per = float(format(psutil.virtual_memory()[2],'.2f'))
    mem_info = {
#        'total' : mem_total,
        'used' : mem_used,
        'per' : mem_per
    }
    return mem_info

def network():
    #network = psutil.net_io_counters()
    network_sent = float(format(float(psutil.net_io_counters()[0]*8/1024/1024),'.2f'))
    network_recv = float(format(float(psutil.net_io_counters()[1]*8/1024/1024),'.2f'))
    network_info = {
        'S' : network_sent,
        'R' : network_recv
    }
    return network_info

def PlaybackTimingMsgHandler(msg,info):
    msgjson = ast.literal_eval(msg)
    user = msgjson["user"]
    stream = msgjson["stream"]
    time = (int)(msgjson["time"])

    if info.get(user,None) == None and stream.find("index.m3u8") > 0:
        info[user]={}
        info[user][time]=time
        info[user][stream]=stream
        info[user]["start"]=time
        info[user]["end"]=time
        info[user]["e2e"]=0
        info[user]["e2e_min"]=1000
        info[user]["e2e_pre"]=0
        info[user]["e2e_tot"]=0
        info[user]["e2e_avg"]=0
        info[user]["e2e_num"]=0
        info[user]["e2e_max"]=0
        return {"play":[0,0,0],user:[info[user]["e2e"],info[user]["e2e_avg"]]}
    elif info.get(user,None) == None:
        return {}

    if stream.find("index.m3u8") > 0:
        info[user]["end"]=time
        info[user]["e2e"]=info[user]["end"] - info[user]["start"]
        info[user][stream]=stream
        if info[user]["e2e"] < info[user]["e2e_min"]: info[user]["e2e_min"]=info[user]["e2e"]
        if info[user]["e2e"] > info[user]["e2e_max"]: info[user]["e2e_max"]=info[user]["e2e"]
        info[user]["e2e_pre"]=info[user]["e2e"]
        info[user]["e2e_num"]=info[user]["e2e_num"]+1
        info[user]["e2e_tot"]=info[user]["e2e_tot"]+info[user]["e2e"]
        info[user]["e2e_avg"]=int(info[user]["e2e_tot"]/info[user]["e2e_num"])
        info[user]["start"]=time

    e2e_min=int(min([value["e2e_min"] for key,value in info.items()]))
    e2e_max=int(max([value["e2e_max"] for key,value in info.items()]))
    e2e_tot=0
    e2e_num=0
    e2e_avg=0
    for key,value in info.items():
        e2e_tot=e2e_tot+value["e2e_tot"]
        e2e_num=e2e_num+value["e2e_num"]

    if e2e_num != 0:
        e2e_avg=int(e2e_tot/e2e_num)

    return {"play":[e2e_min,e2e_avg,e2e_max],user:[info[user]["e2e"],info[user]["e2e_avg"],'*']}

def AnalyticMsgHandler(msg,info):
    msgjson = ast.literal_eval(msg)
    user = msgjson["user"]
    fps = int(msgjson["fps"])
    kafka_wait_time = float(format(float(msgjson["kafka_wait_time"]),".2f"))
    seg_elapsed_time = float(format(float(msgjson["seg_elapsed_time"]),".2f"))
    machine_fps_avg = msgjson["fps_avg"]
    machine_fps_tot = msgjson["fps_tot"]
    machine_seg_num = msgjson["seg_num"]

    if info.get(user,None) == None:
        info[user]={}
        info[user]["fps"]=fps
        info[user]["fps_avg_machine"]=machine_fps_avg
        info[user]["fps_tot_machine"]=machine_fps_tot
        info[user]["seg_num_machine"]=machine_seg_num
        info[user]["fps_avg"]=fps
        info[user]["fps_tot"]=fps
        info[user]["seg_num"]=1
        info[user]["fps_min"]=fps
        info[user]["fps_max"]=fps
        info[user]["kafka_wait_time"]=kafka_wait_time
        info[user]["kafka_wait_time_tot"]=kafka_wait_time
        info[user]["seg_elapsed_time"]=seg_elapsed_time
        return {"fps":[fps,fps,fps],user:[info[user]["fps"],info[user]["kafka_wait_time"],info[user]["seg_elapsed_time"]]}

    info[user]["fps"]=fps
    info[user]["kafka_wait_time"]=kafka_wait_time
    info[user]["kafka_wait_time_tot"]=info[user]["kafka_wait_time_tot"]+kafka_wait_time
    info[user]["seg_elapsed_time"]=seg_elapsed_time
    if info[user]["fps"] < info[user]["fps_min"]: info[user]["fps_min"]=info[user]["fps"]
    if info[user]["fps"] > info[user]["fps_max"]: info[user]["fps_max"]=info[user]["fps"]
    info[user]["fps_tot"]=info[user]["fps_tot"]+info[user]["fps"]
    info[user]["seg_num"]=info[user]["seg_num"]+1   
    info[user]["fps_avg"]=int(info[user]["fps_tot"]/info[user]["seg_num"])

    e2e_min=int(min([value["fps_min"] for key,value in info.items()]))
    e2e_max=int(max([value["fps_max"] for key,value in info.items()]))
    seg_wait_time_tot=0
    seg_wait_time_avg=0
    e2e_tot=0
    e2e_num=0
    e2e_avg=0
    for key,value in info.items():
        e2e_tot=e2e_tot+value["fps_tot"]
        e2e_num=e2e_num+value["seg_num"]
        seg_wait_time_tot=seg_wait_time_tot+value["kafka_wait_time_tot"]
    if e2e_num != 0:
        e2e_avg=int(e2e_tot/e2e_num)
        seg_wait_time_avg= float(format(seg_wait_time_tot/e2e_num,'.2f'))
    #return {key:value["fps_avg"] for key,value in info.items()}, {"min":e2e_min,"avg":e2e_avg,"max":e2e_max} 
    #return {"min":e2e_min,"avg":e2e_avg,"max":e2e_max, user:str(info[user]["fps"])+"/"+str(info[user]["fps_avg"])} 
    return {"fps":[e2e_min,e2e_avg,e2e_max],user:[info[user]["fps"],{"wait":[info[user]["kafka_wait_time"],seg_wait_time_avg]},info[user]["seg_elapsed_time"]]}

def AdRateMsgHandler(msg,info):
    msgjson = ast.literal_eval(msg)
    user = msgjson["user"]
    ad_request_tot = msgjson["ad_request_tot"]
    ad_request_suc = msgjson["ad_request_suc"]
    if ad_request_tot > info["ad_request_tot"]:
        info["ad_request_tot"]=ad_request_tot
        info["ad_request_suc"]=ad_request_suc
    else:
        ad_request_tot=info["ad_request_tot"]
        ad_request_suc=info["ad_request_suc"]

    ad_request_tot_cur=ad_request_tot - info["ad_request_tot_pre"]
    ad_request_suc_cur=ad_request_suc - info["ad_request_suc_pre"]
    ad_rate = float(format(float(ad_request_suc_cur/ad_request_tot_cur),'.2f'))
    return [ad_request_suc_cur,ad_request_tot_cur,ad_rate]

if __name__ == "__main__":
    c = Consumer(None)

    prefix="";
    if len(sys.argv)>1: prefix=sys.argv[1]
    instance=socket.gethostname()[0:3]
    machine=prefix+instance

    interval=1
    info={}
    playback_info={}
    analytic_info={}
    adrate_info=adrate_info_template
    while True:
        try:
            print("Workload: listening to messages", flush=True)
            for topic in kafka_topics:
                for msg in c.messages(topic):
                    #print("Workload: "+str(msg)+" "+topic,flush=True)
                    msgjson = ast.literal_eval(msg)
                    user=msgjson["user"]
                    msgtype=msgjson["type"]
                    info["time"]=int(time.mktime(datetime.datetime.now().timetuple()))
                    #info["machine"]= machine
                    #info["cpu"]=psutil.cpu_percent(interval=interval)
                    info["cpu"]=psutil.cpu_percent()
                    info["mem"]=mem()
                    info["net"]=network()

                    try:
                       if msgtype == "playback":
                           info["e2e"]=PlaybackTimingMsgHandler(msg,playback_info)
                           #print(playback_info,flush=True)i
                       elif ("play" in info.keys()) and (user in playback_info.keys()):
                           info["e2e"]={"play":info["e2e"]["play"],user:[playback_info[user]["e2e"],playback_info[user]["e2e_avg"],"-"]}

                       if msgtype == "analytic":
                           info["seg"]=AnalyticMsgHandler(msg,analytic_info)
                           #print(analytic_info,flush=True)
                       if msgtype == "adrate":
                           info["ad"]=AdRateMsgHandler(msg,adrate_info)
                           #print(adrate_info,flush=True)
                    except Exception as e:
                        print("Workload err: "+str(e), flush=True)

                    if clear_log() == '1':
                        info={}
                        playback_info={}
                        analytic_info={}
                        adrate_info["ad_request_tot_pre"]=adrate_info["ad_request_tot"]
                        adrate_info["ad_request_suc_pre"]=adrate_info["ad_request_suc"]
 
                    print(info,flush=True)
        except Exception as e:
            print(str(e))
            time.sleep(interval)
    c.close()

