#!/usr/bin/python3
## Test
##########################################
 # program name : js_db2support_info.py
 # Copyright : 2020 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Getting environment summary from a db2support directory
 #
 # Category : DB2 support
 # NOTE : Python 3.5+ compatible
 # Date : 
 #
 # Revision History
 # - 
##########################################

import sys
import glob
from pathlib import Path  ## for file search in sub directories

def usage():
        if len(sys.argv) !=2:  # should use 2 counting program name
                print("Usage: " + sys.argv[0] + " <db2suport directory path>")
                sys.exit(-1)
                return()


def db2Level(supportPath):
        cnt = 0
        #print ("Searching for the path " + supportPath)
        for path in Path(supportPath).rglob('db2level*'):
                print(" * " + path.name)
                print(path.read_text())
                # Once we get, no need to repeat
                cnt = cnt + 1
                if cnt != 0:
                        break


def psList(supportPath):
        cnt = 0
        #print ("Searching for the path " + supportPath)
        #for path in Path(supportPath).rglob('db2cluster_list.ps_out'):
        for path in Path(supportPath).rglob('db2instance_list.ps_out'):
                print(" * " + path.name)
                print(path.read_text())
                # Once we get, no need to repeat
                cnt = cnt + 1
                if cnt != 0:
                        break

def db2Node(supportPath):
        cnt = 0
        #print ("Searching for the path " + supportPath)
        #for path in Path(supportPath).rglob('db2cluster_list.ps_out'):
        for path in Path(supportPath).rglob('db2nodes.cfg.supp_cfg'):
                print(" * " + path.name)
                print(path.read_text())
                # Once we get, no need to repeat
                cnt = cnt + 1
                if cnt != 0:
                        break
        
        
        

def main():
        usage()
        inputPath = sys.argv[1]
        print("* db2support path : " + inputPath + "\n")

        db2Level(inputPath)
        psList(inputPath)
        db2Node(inputPath)

main()