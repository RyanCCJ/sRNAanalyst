import os, sys
import pandas as pd
import numpy as np


###############################
# Filter Sequence Length >= N #
###############################
def filter_length(df, length):
    length_checker = np.vectorize(len)
    length_lst = length_checker(df['read_seq'].values)>=length
    df = df[ length_lst ].reset_index(drop=True)
    return df


#################################
# Change File from CSV to FASTA #
#################################
def to_fasta(df, output, filter=None):
    
    # remain sequence length >= 17
    #df = filter_length(df, length=17)
    #if filter!=None:
    #    df = seq_filter(filter)
    
    # rename fasta file in 1-based with read count
    df.index = df.index + 1
    df['read_name'] = '>' + df.index.astype(str) + '_' + df['read_count'].astype(str)
    df = df[['read_name','read_seq']]
    df.to_csv(output, index=False, header=None, sep='\n')


########################
# Collapse Read Counts #
########################
def collapse(data, output=None):

    # sequence is not empty or with 'N'
    def checked(sequence):
        if sequence!='' and sequence!='\n' and 'N' not in sequence:
            return True
        else:
            return False

    # read file into dataframe
    filename, file_extension = os.path.splitext(data)

    if file_extension=='.csv':
        print('csv')
    elif file_extension=='.fasta' or file_extension=='.fa':
        print('fasta')
    elif file_extension=='.fastq' or file_extension=='.fq':    
        i = 0
        gene_lst = []
        with open(data, 'r') as f:
            for line in f:
                if i%4==1 and checked(line):
                    gene_lst.append(line[:len(line)-1])
                i += 1
        df = pd.DataFrame(gene_lst, columns =['read_seq'])
        df['read_count'] = 1
    else:
        print("Unknown file extension {}, which can only be 'fasta', 'fastq' or 'csv'.".format(file_extension))
        sys.exit(0)
    
    # collapse read counts
    df = df.groupby('read_seq').count().reset_index()

    # output file
    if output==None:
        return df
    else:
        filename, file_extension = os.path.splitext(data)
        if file_extension=='.csv':
            print('csv')
        elif file_extension=='.fasta' or file_extension=='.fa':
            to_fasta(df, output)
        elif file_extension=='.fastq' or file_extension=='.fq':
            print('fastq')


# bowtie to csv
def bowtie_to_csv(bwt,read_df,ref_df=None):
    # read bowtie file
    df = pd.read_csv(bwt, sep='\t', names=['input_id','1','ref_id','target_pos','input_seq','2','3','4'])

    # get position
    df['init_pos'] = df['target_pos']+1
    length_checker = np.vectorize(len)
    length_lst = length_checker(df['input_seq'].values)
    df['end_pos'] = df['target_pos'] + length_lst
    df['ref_len'] = length_lst
    df['rem_tran_target_pos'] = df['init_pos'].astype(str) + '-' + df['end_pos'].astype(str)

    # only remain "read length = reference length"
    if ref_df!=None:
        df = pd.merge(df, ref_df, how='inner', on=['ref_id','ref_len'])

    # append read count
    tmp_df = read_df[['input_id','read_count']]
    df = pd.merge(df, tmp_df, how='inner', on='input_id')

    # correct read count
    tmp_df = pd.DataFrame()
    tmp_df['dup'] = df.pivot_table(columns=['input_id'], aggfunc='size')
    df = pd.merge(df, tmp_df, how='left', on='input_id')
    df['norm_rc'] = df['read_count']/df['dup']

    # delete unnecessary columns
    df.drop(['1','2','3','4','target_pos','ref_len','dup'], axis=1, inplace=True)
    
    return df  