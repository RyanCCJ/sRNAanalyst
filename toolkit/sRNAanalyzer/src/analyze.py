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


#################################
# Set Config Files for Analysis #
#################################
def set_config(config, tool, set_stylesheet=True):
    
    if tool=='density':
        config['run_config']['Density']['data'] = merge_config(
            target = config['run_config']['Density']['data'], 
            source = config['samples']['data'],
            on = 'name')
        config['plot_config']['Density']['filter'] = merge_config(
            target = config['plot_config']['Density']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        if set_stylesheet:
            config['plot_config']['Density'].update(config['stylesheet']['General'])
            config['plot_config']['Density'].update(config['stylesheet']['Box_Plot'])
    
    elif tool=='metagene':
        config['run_config']['Metagene']['data'] = merge_config(
            target = config['run_config']['Metagene']['data'], 
            source = config['samples']['data'],
            on = 'name')
        config['plot_config']['Metagene']['filter'] = merge_config(
            target = config['plot_config']['Metagene']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        if set_stylesheet:
            config['plot_config']['Metagene'].update(config['stylesheet']['General'])
            config['plot_config']['Metagene'].update(config['stylesheet']['Line_Plot'])

    elif tool=='boundary':
        config['run_config']['Boundary']['data'] = merge_config(
            target = config['run_config']['Boundary']['data'], 
            source = config['samples']['data'],
            on = 'name')
        config['plot_config']['Head']['filter'] = merge_config(
            target = config['plot_config']['Head']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        config['plot_config']['Tail']['filter'] = merge_config(
            target = config['plot_config']['Tail']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        if set_stylesheet:
            config['plot_config']['Head'].update(config['stylesheet']['General'])
            config['plot_config']['Head'].update(config['stylesheet']['Line_Plot'])
            config['plot_config']['Tail'].update(config['stylesheet']['General'])
            config['plot_config']['Tail'].update(config['stylesheet']['Line_Plot'])
    
    elif tool=='codon':
        config['run_config']['Codon']['data'] = merge_config(
            target = config['run_config']['Codon']['data'], 
            source = config['samples']['data'],
            on = 'name')
        config['plot_config']['Start_Codon']['filter'] = merge_config(
            target = config['plot_config']['Start_Codon']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        config['plot_config']['Stop_Codon']['filter'] = merge_config(
            target = config['plot_config']['Stop_Codon']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        if set_stylesheet:
            config['plot_config']['Start_Codon'].update(config['stylesheet']['General'])
            config['plot_config']['Start_Codon'].update(config['stylesheet']['Line_Plot'])
            config['plot_config']['Stop_Codon'].update(config['stylesheet']['General'])
            config['plot_config']['Stop_Codon'].update(config['stylesheet']['Line_Plot'])

    elif tool=='fold':
        config['run_config']['Fold_Change']['data'] = merge_config(
            target = config['run_config']['Fold_Change']['data'], 
            source = config['samples']['data'],
            on = 'name')
        config['plot_config']['Fold_Change']['filter'] = merge_config(
            target = config['plot_config']['Fold_Change']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        if set_stylesheet:
            config['plot_config']['Fold_Change'].update(config['stylesheet']['General'])
            config['plot_config']['Fold_Change'].update(config['stylesheet']['Box_Plot'])

    elif tool=='scatter':
        config['run_config']['Scatter']['data'] = merge_config(
            target = config['run_config']['Scatter']['data'], 
            source = config['samples']['data'],
            on = 'name')
        config['plot_config']['Scatter']['filter'] = merge_config(
            target = config['plot_config']['Scatter']['filter'], 
            source = config['samples']['filter'],
            on = 'name')
        if set_stylesheet:
            config['plot_config']['Scatter'].update(config['stylesheet']['General'])
            config['plot_config']['Scatter'].update(config['stylesheet']['Scatter_Plot'])
    
    return config


################
# Run Analysis #
################
def run(config, tool):

    if tool=='density':
        density_plot(config['run_config']['Density'], config['plot_config']['Density'])
    
    elif tool=='metagene':
        metagene_plot(config['run_config']['Metagene'], config['plot_config']['Metagene'])

    elif tool=='boundary':
        position_plot(run_config=config['run_config']['Boundary'],)
        arg = [(None,config['plot_config']['Head']),
                (None,config['plot_config']['Tail'])]
        pool = multiprocessing.Pool()
        pool.starmap(position_plot,arg)
        pool.close()
        pool.join()
    
    elif tool=='codon':
        position_plot(run_config=config['run_config']['Codon'])
        arg = [(None,config['plot_config']['Start_Codon']),
                (None,config['plot_config']['Stop_Codon'])]
        pool = multiprocessing.Pool()
        pool.starmap(position_plot,arg)
        pool.close()
        pool.join()

    elif tool=='fold':
        fold_change_plot(config['run_config']['Fold_Change'], config['plot_config']['Fold_Change'])

    elif tool=='scatter':
        scatter_plot(config['run_config']['Scatter'], config['plot_config']['Scatter'])
    

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
    config = {
        'run_config': read_config([base_path+'/run_config.yml']),
        'plot_config': read_config([base_path+'/plot_config.yml']),
        'samples': read_config([base_path+'/samples.yml']),
        'stylesheet': read_config([base_path+'/stylesheet.yml']),
    }
    
    if args.density: 
        config = set_config(config, 'density')
        run(config, 'density')

    if args.metagene:
        config = set_config(config, 'metagene')
        run(config, 'metagene')
    
    if args.boundary:
        config = set_config(config, 'boundary')
        run(config, 'boundary')
        
    if args.codon:
        config = set_config(config, 'codon')
        run(config, 'codon')
    
    if args.fold:
        config = set_config(config, 'fold')
        run(config, 'fold')
    
    if args.scatter:
        config = set_config(config, 'scatter')
        run(config, 'scatter')

    print("Program end with success.")
    print("Time:{:.3f}s".format(time.time()-T))
    