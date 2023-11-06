#!/bin/bash
# -------------------

BASE_DIR=$(pwd)
task=${BASE_DIR}/toolkit/sRNAanalyzer/src/analyze.py
config_path=${BASE_DIR}/toolkit/sRNAanalyzer/config

python $task --config $config_path --density --metagene --boundary --codon --fold --scatter
