#!/bin/bash

# add variables
DATA=$1
BASE_DIR=$(pwd)
LOG_FILE=${BASE_DIR}/preprocess/log
source ${BASE_DIR}/pipeline/NGS_preprocess.conf

# trim adapter
echo "step1. trim adapter"
cutadapt --cores 4 --max-n 0 -a ${adapter} $DATA | \
cutadapt --cores 4 -u ${UMI} -u -${UMI} -m 17 - > ${data}_trimmed.fq

# collapse duplicated reads
echo "step2. calculate normalize factor"
task=${BASE_DIR}/preprocess/toolkit/drap/preprocess.py
python $task --collapse -i ${data}_trimmed.fq --format fasta -o ${data}_collapsed.fa

# normalize read count
ref=${BASE_DIR}/data/c_elegans/transcript/miRNA_WS285.fa
tmp=${BASE_DIR}/preprocess/metadata/tmp/miRNA_WS285
bowtie2-build $ref $tmp --threads 8
bowtie2 -x $tmp -f ${data}_collapsed.fa -S ${data}_mapped.sam --threads 8 -a --score-min "C,0,0" --norc --no-unal --no-hd
python $task --merge "ref:read_seq" -i ${data}_mapped.sam -r $ref | \
python $task --distribute | \
python $task --norm_factor -o ${data}_mapped.csv
	
norm_factor=$(awk '$0 ~ /# norm_factor/{split($0,a,"="); print a[2]}' ${data}_mapped.csv)
echo "Normaliation Factor: $norm_factor"

# find 22G
echo "step3. find 22G"
python $task --filter ${NGS_filter} -i ${data}_collapsed.fa | \
python $task --rc --format fasta -o ${data}_filtered.fa

# map to mRNA
ref=${BASE_DIR}/data/c_elegans/transcript/mRNA_WS285.fa
tmp=${BASE_DIR}/preprocess/metadata/tmp/mRNA_WS285
bowtie2-build $ref $tmp --threads 8
bowtie2 -x $tmp -f ${data}_filtered.fa -S ${data}_mapped.sam --threads 8 -a --score-min "C,0,0" --norc --no-unal --no-hd
python $task --distribute -i ${data}_mapped.sam | \
python $task --normalize $norm_factor -o ${data}.csv
	
# -------------------
	
# remove metadatas
rm ${data}_trimmed.fq
rm ${data}_collapsed.fa
rm ${data}_filtered.fa
rm ${data}_mapped.sam
rm ${data}_mapped.csv

# trim adapter
echo "step1. trim adapter"
input=${BASE_DIR}/data/${DATA}
data=${BASE_DIR}/preprocess/metadata/${DATA%.*}
cutadapt --cores=4 -a ${adapter} $input | \
cutadapt --cores=4 -u ${UMI} -u -${UMI} -m ${min_length} - > ${data}_trimmed.fq
		
# collapse duplicated reads
task=${BASE_DIR}/preprocess/toolkit/drap/preprocess.py
python3 $task --collapse ${data}_trimmed.fq -o ${data}_collapsed.fa

# find 22G
python3 $task --filter ${NGS_filter} ${data}_collapsed.fa -o ${data}_filtered.fa
python3 $task --rc ${data}_filtered.fa -o ${data}_filtered.fa
	
# normalize read count
python3 $task --filter ":>=17:" ${data}_collapsed.fa -o ${data}_filtered.fa
ref=${BASE_DIR}/data/${DATA}/c_elegans/transcript/miRNA_WS285.fa
tmp=${BASE_DIR}/preprocess/metadata/tmp/miRNA_WS285
bowtie-build $ref $tmp
bowtie ${bowtie} -f $tmp ${data}_filtered.fa ${data}_mapped.bwt
python3 $task --to_csv -i ${data}_mapped.bwt | \
python3 $task --distribute_rc -o ${data}_mapped.csv
	
norm_factor=$(pyhton3 $task --norm_factor ${data}_mapped.csv)
echo "Normaliation Factor: $norm_factor"

# map to mRNA
ref=${BASE_DIR}/data/${DATA}/c_elegans/transcript/mRNA_WS285.fa
tmp=${BASE_DIR}/preprocess/metadata/tmp/mRNA_WS285
bowtie-build $ref $tmp
bowtie ${bowtie} -f $tmp ${data}_filtered.fa ${data}_mapped.bwt
python3 $task --to_csv -i ${data}_mapped.bwt | \
python3 $task --distribute_rc | \
python3 $task --normalize -f norm_factor -o ${data}.csv

# remove metadatas
rm ${data}_trimmed.fq
rm ${data}_collapsed.fa
rm ${data}_filtered.fa
rm ${data}_mapped.bwt
rm ${data}_mapped.csv
