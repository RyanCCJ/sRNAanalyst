#!/bin/bash
# -------------------

BASE_DIR=$(pwd)
task=${BASE_DIR}/toolkit/drap/src/analyze.py
config_path=${BASE_DIR}/toolkit/drap/config

python $task --config $config_path --density --metagene --boundary --codon --fold --scatter
