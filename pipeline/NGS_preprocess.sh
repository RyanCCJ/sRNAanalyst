#!/bin/bash
# -------------------

# add variables
#input=$1
#data=${BASE_DIR}/preprocess/metadata/${DATA%.*}
BASE_DIR=$(pwd)
. ${BASE_DIR}/pipeline/NGS_preprocess.conf
input=${BASE_DIR}/${input_file}
output=${BASE_DIR}/${output_dir}
data=${BASE_DIR}/${output_dir}/${base_name}
log=${BASE_DIR}/${output_dir}/log/${base_name}
task=${BASE_DIR}/toolkit/drap/src/preprocess.py

# -------------------
echo "step1. trim adapter"

# trim adapter
cutadapt --cores ${CPU_core} --max-n 0 -a ${adapter} ${input} 2> ${log}_cutadapt_trim-adapter.log | \
cutadapt --cores ${CPU_core} -u ${UMI} -u -${UMI} -m 17 - > ${data}_trimmed.fq 2> ${log}_cutadapt_trim-UMI.log

# -------------------
echo "step2. calculate normalize factor"

# collapse duplicated reads
python $task --collapse -i ${data}_trimmed.fq --format fasta -o ${data}_collapsed.fa

# normalize read count
ref=${BASE_DIR}/data/c_elegans/transcript/miRNA_WS285.fa
tmp=${output}/tmp/miRNA_WS285
bowtie2-build $ref $tmp --threads ${CPU_core} > ${log}_bowtie2-build_normalize.log 2>&1
bowtie2 -x $tmp -f ${data}_collapsed.fa -S ${data}_mapped.sam --threads ${CPU_core} ${bowtie} > ${log}_bowtie2_normalize.log 2>&1
python $task --merge "ref:read_seq" -i ${data}_mapped.sam -r $ref | \
python $task --distribute | \
python $task --norm_factor -o ${data}_mapped.csv
	
norm_factor=$(awk '$0 ~ /# norm_factor/{split($0,a,"="); print a[2]}' ${data}_mapped.csv)
echo "Normaliation Factor: $norm_factor"

# -------------------
echo "step3. find 22G"

# find 22G
python $task --filter ${filter} -i ${data}_collapsed.fa | \
python $task --rc --format fasta -o ${data}_filtered.fa

# map to mRNA
ref=${BASE_DIR}/data/c_elegans/transcript/mRNA_WS285.fa
tmp=${output}/tmp/mRNA_WS285
bowtie2-build $ref $tmp --threads ${CPU_core} > ${log}_bowtie2-build.log 2>&1
bowtie2 -x $tmp -f ${data}_filtered.fa -S ${data}_mapped.sam --threads ${CPU_core} ${bowtie} > ${log}_bowtie2.log 2>&1
python $task --distribute -i ${data}_mapped.sam | \
python $task --normalize $norm_factor -o ${data}.csv
	
# -------------------
	
# remove metadatas
if [ $delete_metadata = true ]; then
    rm ${data}_trimmed.fq
    rm ${data}_collapsed.fa
    rm ${data}_filtered.fa
    rm ${data}_mapped.sam
    rm ${data}_mapped.csv
fi
