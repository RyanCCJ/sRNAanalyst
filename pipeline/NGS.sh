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
		exit 1
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

	# defined file path
	filename=$(basename ${DATA})
	data=${BASE_DIR}/preprocess/metadata/${filename%.*}

	# -------------------
	
	echo "step1. trim adapter"
	# trim adapter
	#cutadapt --max-n 0 -a TGGAATTCTCGGGTGCCAAGG $DATA | \
	#cutadapt -u 4 -u -4 -m 17 - > ${data}_trimmed.fq
	
	# -------------------

	echo "step2. calculate normalize factor"
	# collapse duplicated reads
	task=${BASE_DIR}/preprocess/toolkit/drap/preprocess.py
	#python $task --collapse -i ${data}_trimmed.fq --format fasta -o ${data}_collapsed.fa

	# normalize read count
	ref=${BASE_DIR}/data/c_elegans/transcript/miRNA_WS285.fa
	tmp=${BASE_DIR}/preprocess/metadata/tmp/miRNA_WS285
	#bowtie2-build $ref $tmp --threads 8
	bowtie2 -x $tmp -f ${data}_collapsed.fa -S ${data}_mapped.sam --threads 8 -a --score-min "C,0,0" --norc --no-unal --no-hd
	python $task --merge "ref:read_seq" -i ${data}_mapped.sam -r $ref | \
	python $task --distribute | \
	python $task --norm_factor -o ${data}_mapped.csv
	
	norm_factor=$(awk '$0 ~ /# norm_factor/{split($0,a,"="); print a[2]}' ${data}_mapped.csv)
	echo "Normaliation Factor: $norm_factor"
	
	# -------------------
	
	echo "step3. find 22G"
	# find 22G
	python $task --filter "G:22-23:" -i ${data}_collapsed.fa | \
	python $task --rc --format fasta -o ${data}_filtered.fa

	# map to mRNA
	ref=${BASE_DIR}/data/c_elegans/transcript/mRNA_WS285.fa
	tmp=${BASE_DIR}/preprocess/metadata/tmp/mRNA_WS285
	#bowtie2-build $ref $tmp --threads 8
	bowtie2 -x $tmp -f ${data}_filtered.fa -S ${data}_mapped.sam --threads 8 -a --score-min "C,0,0" --norc --no-unal --no-hd
	python $task --distribute -i ${data}_mapped.sam | \
	python $task --normalize $norm_factor -o ${data}.csv
	
	# -------------------
	
	# remove metadatas
	#rm ${data}_trimmed.fq
	#rm ${data}_collapsed.fa
	#rm ${data}_filtered.fa
	#rm ${data}_mapped.sam
	#rm ${data}_mapped.csv
}


################
# Main Program #
################
get_options $@
pipeline #>> $LOG_FILE 2>&1
