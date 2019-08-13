#!/usr/bin/python3

from tornado import web, gen
import json
import requests
from adkeyword import GetAdKeywords, GetMaxKeyword, GetAttrKeyword
import random

ad_decision_post_reponse_template = {
    "source": {
        "uri": "string",
        },
    "keywords": [],
    "overlay": [
        {
        "start_frame": 10,
        "stop_frame": 50,
        "x_ratio" : 0.2,
        "y_ratio" : 0.8,
        "text": "string"
        }
        ]
}

ad_content_server="http://ad-content:8080/"

#TODO: add database to store this info
inventory_template = [
    {'uri' : 'http://ad-content:8080/car.mp4',
     'navigation_url' : 'http://www.intel.com',
     'keywords' : ['car', 'sports'],
     'duration' : '7'
    },
    {'uri' : 'http://ad-content:8080/cat1.mp4',
     'navigation_url' : 'http://www.intel.com',
     'keywords' : ['cat', 'pets'],
     'duration' : '3'
    },
    {'uri' : 'http://ad-content:8080/dog4.mp4',
     'navigation_url' : 'http://www.intel.com',
     'keywords' : ['dog', 'pets'],
     'duration' : '7'
    }
]

timeout=30

def clip(adkeyword):
    #num = len(ad_clip["adkeyword"])
    for idx, item in enumerate(ad_clip["adkeyword"]):
        if item != None:
            return item

class MetaDataHandler(web.RequestHandler):
    def __init__(self, app, request, **kwargs):
        super(MetaDataHandler, self).__init__(app, request, **kwargs)
        self.inventory = None
        self.keywords = []
        self.user_keywords = []
        self.bench_mode = 0
        
    def check_origin(self, origin):
        return True

    def getclip(self):
        clip_matched_list=[]
        for idx_clip, clip in enumerate(self.inventory):
            clip_matched_list.append(0)
            for idx_item,item in enumerate(self.keywords):
                if item["keyword"] in clip["keywords"]:
                    clip_matched_list[idx_clip] += item["num"]

            for item in self.user_keywords:
                if item in clip["keywords"]:
                    clip_matched_list[idx_clip] += 1

        max_value = max(clip_matched_list)
        #print(self.inventory,flush=True)
        print(self.keywords,flush=True)
        print(clip_matched_list,flush=True)

        max_matched_idx=-1
        if max_value == 0:
            if self.bench_mode:
                max_matched_idx = random.randint(0,len(self.inventory))
                return self.inventory[max_matched_idx]["uri"]
            return None
        else:
            if clip_matched_list.count(max_value) == 1:
                max_matched_idx=clip_matched_list.index(max_value)
            else:
                clip_idx=[]
                for _idx, num in enumerate(clip_matched_list):
                    if num == max_value: clip_idx.append(_idx)
                max_matched_idx = clip_idx[random.randint(0,len(clip_idx)-1)]
        print(max_matched_idx,flush=True)
        print(self.inventory[max_matched_idx]["uri"],flush=True)
        return self.inventory[max_matched_idx]["uri"]

    @gen.coroutine
    def get(self):
        self.set_status(200,"OK")
        self.set_header("Content-Type", "application/json")
        self.write(json.dumps([{"MetaDataHandler":"Get"}]))
        self.write(json.dumps([ad_decision_post_reponse_template]))
        self.write(json.dumps(self.inventory))

    @gen.coroutine
    def post(self):
        if self.inventory == None:
            try:
                r = requests.get(ad_content_server+"inventory",timeout=timeout)
                if r.status_code == 200:
                    self.inventory = r.json()
            except requests.exceptions.RequestException as e:  # This is the correct syntax
                print("ad content server: Error sending status request " + str(e), flush=True)

        try:
            random.shuffle(self.inventory)
            #print(self.request.body.decode('utf-8'))
            data = json.loads(self.request.body.decode('utf-8'))
            self.user_name = data["user"]["name"]
            self.user_keywords = data["user"]["keywords"]
            self.bench_mode = data["bench_mode"]
            # parse the meta data and choose the keyword, the data is the list of meta data
            self.keywords = GetAdKeywords(data["metadata"])
            # select a ad clip according to the keyword
            response_data = ad_decision_post_reponse_template
            response_data["source"]["uri"] = self.getclip()
            response_data["keywords"] = self.keywords

            self.set_status(200,"OK")
            self.set_header("Content-Type", "application/json")
            self.write(json.dumps([response_data]))
            # debug
            #self.write(json.dumps(self.keywords))
            #self.write(json.dumps(data))

        except Exception as e:
            self.set_status(503, "exception when post")
            print(str(e))

