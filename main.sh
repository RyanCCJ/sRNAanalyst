#!/bin/bash
##################################
# Copyright (C) 2023 Ryan Chung  #
#                                #
# History:                       #
# 2023/01/20 Ryan Chung          #
# 			 Original code.      #
##################################


#BASE_DIR=$(dirname $(pwd))
BASE_DIR=$(pwd)
LOG_FILE=${BASE_DIR}/preprocess/log
DATA=unset


#################################
# Command Line Help Discription #
#################################
display_help() {
	echo "
	NGS sRNA preprocess pipeline with adapter trimming, RNA mapping and normalization.

	Usage: NGS.sh [-s] [-d] [-h]

	Options:
	-s	Input pipeline script.
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
		while getopts ":d:s:h" option
		do
			case $option in
				d) # get data path
					DATA=$OPTARG
					;;
				s) # get script path
					SCRIPT=$OPTARG
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


################
# Main Program #
################
get_options $@
sh pipeline/${SCRIPT}
#pipeline >> $LOG_FILE 2>&1
