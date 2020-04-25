{
  "json_schema_version" : "1.0.0",
  "input_preproc": [
    {
      "layer_name": "0",
      "color_format": "BGR",
      "converter": "alignment",
      "alignment_points": [
        0.31556875000000000,
        0.4615741071428571,
        0.68262291666666670,
        0.4615741071428571,
        0.50026249999999990,
        0.6405053571428571,
        0.34947187500000004,
        0.8246919642857142,
        0.65343645833333330,
        0.8246919642857142
      ]
    }
  ],
  "output_postproc": [
    {
      "layer_name": "658",
      "attribute_name": "face_id",
      "format": "cosine_distance"
    }
  ]
}
