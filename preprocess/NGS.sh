#!/bin/bash
##################################
# Copyright (C) 2023 Ryan Chung  #
#                                #
# History:                       #
# 2023/01/20 Ryan Chung          #
# 			 Original code.      #
##################################


BASE_DIR=$(dirname $(pwd))
LOG_FILE=${BASE_DIR}/preprocess/log
DATA=unset


#################################
# Command Line Help Discription #
#################################
display_help() {
	echo "
	NGS sRNA preprocess pipeline with adapter trimming, RNA mapping and normalization.

	Usage: NGS.sh [-d] [-h]

	Options:
	-d	Input NGS data.
	-h	Show this message.
	"
}


###########################
# Obtain Script Arguments #
###########################
get_options() {
	if [ -z $1 ]; then
		# no arguments
		echo "Error: Empty options."
		echo "Please enter '-h' for more details."
		exit 0
	else
		while getopts ":d:h" option
		do
			case $option in
				d) # get data path
					DATA=$OPTARG
					;;
				h) # display Help
					display_help
					exit 0
					;;	
				?) # incorrect option
					echo "Error: Invalid options."
					echo "Please enter '-h' for more details."
					exit 0
					;;
			esac
		done
	fi
}


############################
# Main Preprocess Pipeline #
############################
pipeline() {

	# trim adapter
	input=${BASE_DIR}/data/${DATA}
	data=${BASE_DIR}/preprocess/metadata/${DATA%.*}
	cutadapt -a TGGAATTCTCGGGTGCCAAGG $input -o ${data}_trimmed.fq
	cutadapt -u 4 -u -4 ${data}_trimmed.fq -o ${data}_trimmed.fq
		
	# collapse duplicated reads
	task=${BASE_DIR}/preprocess/toolkit/drap/preprocess.py
	python3 $task --collapse ${data}_trimmed.fq -o ${data}_collapsed.fa

	# find 22G
	python3 $task --filter "G:22-23:" ${data}_collapsed.fa -o ${data}_filtered.fa
	python3 $task --rc ${data}_filtered.fa -o ${data}_filtered.fa
	
	# normalize read count
	python3 $task --filter ":>=17:" ${data}_collapsed.fa -o ${data}_filtered.fa
	ref=${BASE_DIR}/data/${DATA}/c_elegans/transcript/miRNA_WS285.fa
	tmp=${BASE_DIR}/preprocess/metadata/tmp/miRNA_WS285
	bowtie-build $ref $tmp
	bowtie -f -a -v 0 --norc $tmp ${data}_filtered.fa ${data}_mapped.bwt
	python3 $task --to_csv -i ${data}_mapped.bwt | \
	python3 $task --distribute_rc -o ${data}_mapped.csv
	
	norm_factor=$(pyhton3 $task --norm_factor ${data}_mapped.csv)
	echo "Normaliation Factor: $norm_factor"

	# map to mRNA
	ref=${BASE_DIR}/data/${DATA}/c_elegans/transcript/mRNA_WS285.fa
	tmp=${BASE_DIR}/preprocess/metadata/tmp/mRNA_WS285
	bowtie-build $ref $tmp
	bowtie -f -a -v 0 --norc $tmp ${data}_filtered.fa ${data}_mapped.bwt
	python3 $task --to_csv -i ${data}_mapped.bwt | \
	python3 $task --distribute_rc | \
	python3 $task --normalize -f norm_factor -o ${data}.csv

	# remove metadatas
	rm ${data}_trimmed.fq
	rm ${data}_collapsed.fa
	rm ${data}_filtered.fa
	rm ${data}_mapped.bwt
	rm ${data}_mapped.csv
}


################
# Main Program #
################
get_options
#pipeline >> $LOG_FILE 2>&1
