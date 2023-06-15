##################################
# Copyright (C) 2023 Ryan Chung  #
#                                #
# History:                       #
# 2023/04/10 Ryan Chung          #
#            Original code.      #
##################################

import argparse
import multiprocessing
import os
import time
import yaml
from utility import density_plot, metagene_plot, position_plot, fold_change_plot, scatter_plot

__version__ = "version 1.0"

###############################
# Read and Merge Config Files #
###############################
def read_config(files=None):

    config = {}
    if files != None:
        for file in files:
            # read config file
            with open(file, 'r') as f:
                try:
                    new_config = yaml.safe_load(f)
                except yaml.YAMLError as exc:
                    print(exc)
            
            # check if keys are duplicated
            for key in new_config.keys():
                if key in config:
                    config[key].update(new_config[key])
                else:
                    config[key] = new_config[key]
    
    return config


##############################
# Merge two Configs on a Key #
##############################
def merge_config(target, source, on):
    for config_t in target:
        for config_s in source:
            if config_t[on]==config_s[on]:
                config_t.update(config_s)
                break
    return target


################
# Main Program #
################
if __name__ == '__main__':

    # arguments
    parser = argparse.ArgumentParser(
        description="This program is a to analyze NGS-Seq.",
    )
    parser.add_argument("-v", "--version",
                        action="version",
                        version="%(prog)s " + __version__)
    parser.add_argument("--config",
                        help="analyze read-count into mutiple regions")
    parser.add_argument("--density",
                        action="store_true",
                        help="analyze read-count into mutiple regions")
    parser.add_argument("--metagene",
                        action="store_true",
                        help="analyze read-count into mutiple regions")
    parser.add_argument("--boundary",
                        action="store_true",
                        help="analyze read-count into mutiple regions")
    parser.add_argument("--codon",
                        action="store_true",
                        help="analyze read-count into mutiple regions")
    parser.add_argument("--fold",
                        action="store_true",
                        help="analyze read-count into mutiple regions")
    parser.add_argument("--scatter",
                        action="store_true",
                        help="analyze read-count into mutiple regions")
    args = parser.parse_args()

    # main program
    T = time.time()

    # initialize config
    if args.config!=None:
        base_path = args.config
    else:
        base_path = os.path.abspath(__file__+'/../../config')
    run_config = read_config([base_path+'/run_config.yml'])
    plot_config = read_config([base_path+'/plot_config.yml'])
    samples = read_config([base_path+'/samples.yml'])
    stylesheet = read_config([base_path+'/stylesheet.yml'])
    
    if args.density:
        run_config['Density']['data'] = merge_config(
            target = run_config['Density']['data'], 
            source = samples['data'],
            on = 'name')
        plot_config['Density'].update(stylesheet['General'])
        plot_config['Density'].update(stylesheet['Box_Plot'])
        density_plot(run_config['Density'], plot_config['Density'])

    
    if args.metagene:
        run_config['Metagene']['data'] = merge_config(
            target = run_config['Metagene']['data'], 
            source = samples['data'],
            on = 'name')
        plot_config['Metagene'].update(stylesheet['General'])
        plot_config['Metagene'].update(stylesheet['Line_Plot'])
        metagene_plot(run_config['Metagene'], plot_config['Metagene'])
    
    
    if args.boundary:
        run_config['Boundary']['data'] = merge_config(
            target = run_config['Boundary']['data'], 
            source = samples['data'],
            on = 'name')
        plot_config['Head'].update(stylesheet['General'])
        plot_config['Head'].update(stylesheet['Line_Plot'])
        plot_config['Tail'].update(stylesheet['General'])
        plot_config['Tail'].update(stylesheet['Line_Plot'])
        
        position_plot(run_config=run_config['Boundary'],)

        arg = [(None,plot_config['Head']),
                (None,plot_config['Tail'])]
        pool = multiprocessing.Pool()
        pool.starmap(position_plot,arg)
        pool.close()
        pool.join()


    if args.codon:
        run_config['Codon']['data'] = merge_config(
            target = run_config['Codon']['data'], 
            source = samples['data'],
            on = 'name')
        plot_config['Start_Codon'].update(stylesheet['General'])
        plot_config['Start_Codon'].update(stylesheet['Line_Plot'])
        plot_config['Stop_Codon'].update(stylesheet['General'])
        plot_config['Stop_Codon'].update(stylesheet['Line_Plot'])

        position_plot(run_config=run_config['Codon'])

        arg = [(None,plot_config['Start_Codon']),
                (None,plot_config['Stop_Codon'])]
        pool = multiprocessing.Pool()
        pool.starmap(position_plot,arg)
        pool.close()
        pool.join()
    

    if args.fold:
        run_config['Fold_Change']['data'] = merge_config(
            target = run_config['Fold_Change']['data'], 
            source = samples['data'],
            on = 'name')
        plot_config['Fold_Change'].update(stylesheet['General'])
        plot_config['Fold_Change'].update(stylesheet['Box_Plot'])
        fold_change_plot(run_config['Fold_Change'], plot_config['Fold_Change'])
    
    
    if args.scatter:
        run_config['Scatter']['data'] = merge_config(
            target = run_config['Scatter']['data'], 
            source = samples['data'],
            on = 'name')
        plot_config['Scatter'].update(stylesheet['General'])
        plot_config['Scatter'].update(stylesheet['Scatter_Plot'])
        scatter_plot(run_config['Scatter'], plot_config['Scatter'])
    

    print("Time:{:.3f}s".format(time.time()-T))
    