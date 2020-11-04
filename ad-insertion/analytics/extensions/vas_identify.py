# ==============================================================================
# Copyright (C) 2018-2020 Intel Corporation
#
# SPDX-License-Identifier: MIT
# ==============================================================================

import json
import os
import shutil
from gstgva.util import libgst, gst_buffer_data
from collections import defaultdict
import gi
gi.require_version('Gst', '1.0')
from gi.repository import Gst
import numpy
import uuid
import copy
import operator

def print_message(message):
    print("",flush=True)
    print("*"*len(message),flush=True)
    print(message,flush=True)
    print("*"*len(message),flush=True)


class Capture(object):
    def __init__(self):
        pass

    def process_frame(self,frame):
        try:
            for region in frame.regions():
                for tensor in region.tensors():
                    if tensor.has_field('format'):
                        if tensor['format'] == "cosine_distance":
                            if tensor.has_field('enrolled'):
                                buffer = frame._VideoFrame__buffer
                                with gst_buffer_data(buffer, Gst.MapFlags.READ) as data:
                                    path = "{}.jpeg".format(os.path.splitext(tensor['enrolled'])[0])
                                    with open(path,"wb",0) as output:
                                        output.write(data)
                                
        except Exception as error:
            print_message("Error processing frame: {}".format(error))
            
        return True

        
class Identify(object):

    UNKNOWN_LABEL = "UNKNOWN"
    UNKNOWN_ID = -1

    def _similarity(self,a,b):
        return numpy.dot(a,b)/(numpy.linalg.norm(a)
                               *numpy.linalg.norm(b))
    
    def _load_gallery(self, gallery_path):

        try:

            self._gallery=defaultdict(list)
       
            with open(gallery_path, 'r') as f:
                gallery = json.load(f)

            for feature_map in gallery:
                tensors = []
                for feature_path in feature_map['features']:
                    feature_path = os.path.join(os.path.dirname(gallery_path),feature_path)
                    tensor = numpy.fromfile(feature_path,dtype=numpy.float32)
                    tensors.append(tensor)
                self._gallery[feature_map['name']].extend(tensors)
        except Exception as error:
            self._gallery=defaultdict(list)
        
            
    def _enroll_tensor(self, tensor, region):

        if tensor["label"] == Identify.UNKNOWN_LABEL:

            if (len(self._gallery.keys()) >= self._max_enrolled):
                print_message("Max objects enrolled")
                return
            
            if self._label:
                tensor["label"] = self._label
            else:
                tensor["label"] = str(uuid.uuid1())

            tensor["label_id"] = len(self._gallery.keys())

        if (len(self._gallery[tensor["label"]]) >= self._max_enrolled_tensors):
            print_message("Max tensors enrolled for: {}".format(tensor["label"]))
            return

        self._gallery[tensor["label"]].append(copy.deepcopy(tensor.data()))

        if (self._index == None):
            index = len(self._gallery[tensor["label"]])
        else:
            index = self._index

        print_message("Enrolling: {0} tensor: {1}".format(tensor["label"],index))
            
        output_path=os.path.join(self._features_path,tensor["label"],
                                 '.'.join([tensor["label"],
                                           str(index),
                                           "tensor"]))


        tensor["enrolled"] = output_path
        region.detection()["label_id"] = 3
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, 'wb') as output_file:
            tensor.data().tofile(output_file)

            
    def __init__(self,
                 enroll = False,
                 gallery = "/home/gallery/face_gallery_FP32",
                 threshold = 0.6,
                 label = None,
                 index = None,
                 max_enrolled = 10,
                 max_enrolled_tensors = 10):

        self._enroll = enroll
        self._threshold = threshold
        self._label = label
        self._index = index
        self._gallery_path = os.path.abspath(os.path.join(gallery,"gallery.json"))
        self._features_path = os.path.abspath(os.path.join(gallery,"features"))
        self._max_enrolled_tensors = max_enrolled_tensors
        self._max_enrolled = max_enrolled

        if (enroll):
            os.makedirs(self._features_path,exist_ok=True)

        self._load_gallery(self._gallery_path)
            
    def process_frame(self,frame):
        
        try:
            
            for region in frame.regions():
                for tensor in region.tensors():
                    if tensor.has_field('format'):
                        if tensor['format'] == "cosine_distance":
                            similarities = defaultdict(int)
                            match = Identify.UNKNOWN_LABEL
                            match_id = Identify.UNKNOWN_ID
                            tensor["label"] = Identify.UNKNOWN_LABEL
                            tensor["label_id"] = Identify.UNKNOWN_ID
                            
                            for identity, embeddings in self._gallery.items():          
                                similarities[identity] = max([self._similarity(tensor.data(), embedding) for embedding in embeddings])

                            if similarities:
                                match = max(similarities.items(), key=operator.itemgetter(1))[0]
                                        
                                if (similarities[match]>=self._threshold):
                                    tensor["label"] = str(match)
                                    tensor["label_id"] = match_id

                            print_message("Matched: {0}".format(tensor["label"]))
                            
                            if self._enroll and (similarities[match] < 1):
                                self._enroll_tensor(tensor,region)

        except Exception as error:
            print_message("Error processing frame: {}".format(error))
          
        return True
                            
                    
                               

