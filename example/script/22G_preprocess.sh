#!/bin/bash
# -------------------

# add variables
BASE_DIR=$(dirname $0)/..
. ${BASE_DIR}/script/22G_preprocess.conf
input=${BASE_DIR}/${input_file}
output=${BASE_DIR}/${output_dir}
data=${BASE_DIR}/${output_dir}/${base_name}
log=${BASE_DIR}/${output_dir}/log
task=${BASE_DIR}/../src/srna_preprocess.py

# -------------------
echo "step1. trim adapter"

cutadapt --cores ${CPU_core} --max-n 0 -a ${adapter} ${input} 2> ${log}/cutadapt_trim-adapter.log | \
cutadapt --cores ${CPU_core} -u ${UMI} -u -${UMI} -m ${min_length} - > ${data}_trimmed.fq 2> ${log}/cutadapt_trim-UMI.log

# -------------------
echo "step2. calculate normalize factor"

# collapse duplicated reads
python $task --collapse -i ${data}_trimmed.fq --format fasta -o ${data}_collapsed.fa > ${log}/collapse.log

# normalize read count
ref=${BASE_DIR}/data/miRNA_WS275.fa
bwt=${output}/bwt/miRNA_WS275
bowtie2-build $ref $bwt --threads ${CPU_core} > ${log}/bowtie2-build_normalize.log 2>&1
bowtie2 -x $bwt -f ${data}_collapsed.fa -S ${data}_mapped.sam --threads ${CPU_core} ${bowtie} > ${log}/bowtie2_normalize.log 2>&1
python $task --merge "ref:read_seq" -i ${data}_mapped.sam -r $ref 2> ${log}/normalize.log | \
python $task --distribute 2>>${log}/normalize.log | \
python $task --norm_factor -o ${data}_normalized.csv >> ${log}/normalize.log
	
norm_factor=$(awk '$0 ~ /# norm_factor/{split($0,a,"="); print a[2]}' ${data}_normalized.csv)
echo "Normaliation Factor: $norm_factor"

# -------------------
echo "step3. find 22G"

# find 22G
python $task --filter ${filter} -i ${data}_collapsed.fa 2> ${log}/filter.log | \
python $task --rc --format fasta -o ${data}_filtered.fa >> ${log}/filter.log

# map to mRNA
ref=${BASE_DIR}/data/mRNA_WS275.fa
bwt=${output}/bwt/mRNA_WS275
bowtie2-build $ref $bwt --threads ${CPU_core} > ${log}/bowtie2-build.log 2>&1
bowtie2 -x $bwt -f ${data}_filtered.fa -S ${data}_mapped.sam --threads ${CPU_core} ${bowtie} > ${log}/bowtie2.log 2>&1
python $task --distribute -i ${data}_mapped.sam 2> ${log}/map.log | \
python $task --normalize $norm_factor -o ${data}.csv >> ${log}/map.log

# -------------------
	
# remove metadatas
if [ $delete_metadata = true ]; then
    rm ${data}_trimmed.fq
    rm ${data}_collapsed.fa
    rm ${data}_normalized.csv
    rm ${data}_filtered.fa
    rm ${data}_mapped.sam
    rm ${bwt}*
fi
