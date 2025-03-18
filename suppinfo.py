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
import re # for regular expression   
import glob
from pathlib import Path  ## for file search in sub directories

verbose = False

def usage():
	#if len(sys.argv) !=2:  # should use 2 counting program name
	if len(sys.argv) not in [2, 3]:  # should use 2 counting program name
		print("Usage: " + sys.argv[0] + " <db2suport directory path> [-v|--verbose]")
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


def db2NodeSummary(filename):

	with open(filename, 'r') as f:
		lines = f.readlines()   # read all lines first. this file should be small 
	
	host_dict = {}

	#db2nodesPattern1 = re.compile(r'^\d+ \S+ \d+ \S+$')   ## In case of DPF => 0 host1 0 host1-priv # This does not show single or DPF on single. Changed to the next line  
	db2nodesPattern1 = re.compile(r'^\d+ \S+ \d+')   ## 0 host1 0 
	
	for line in lines:
		line = line.strip()  # chomp  
		if db2nodesPattern1.match(line):
			parts = line.split()  # split by whitespace   
			#print(parts)   # ['0', 'host1', '0', 'host1-priv']
			partNum = int(parts[0])  # partition number 
			hostName = parts[1]  
		
			if hostName in host_dict:  # # Add index to the hostname 'group' if exists
				host_dict[hostName].append(partNum)
			else:
				host_dict[hostName] = [partNum] # first detected partition number for the host  

	#print(host_dict)   # {'host1': [0], 'host2': [1, 2], .... 
	
	#for hostItem in host_dict.items():  # for each key(hostname) ,  retrieve the value as indices  
	#	print(hostItem)

	numHosts = len(host_dict)
	numTotalPartitions = sum(len(indices) for indices in host_dict.values())
	
	if numTotalPartitions > 1:
		print(f"\nDPF : {numTotalPartitions} partitions on {numHosts} hosts")


	print("hostname (# of partitions) Partition range") 
	print("==========================================") 
	for hostname, indices in host_dict.items():  # for each key(hostname) ,  retrieve the value as indices  
		indices.sort()
		if len(indices) == 1:
			print(f"{hostname} ({len(indices)}) {indices[0]}")
		else:

			print(f"{hostname} ({len(indices)}) {indices[0]} - {indices[-1]}")
	
def db2Node(supportPath):
	cnt = 0
	for path in Path(supportPath).rglob('db2nodes.cfg.supp_cfg*'):  # file names could be db2nodes.cfg.supp_cfg or db2nodes.cfg.supp_cfg.txt

		db2NodeSummary(path)
		if verbose:
			print("\n\n * " + path.name)
			print(path.read_text())

		# Once we get, no need to repeat
		cnt = cnt + 1
		if cnt != 0:
			break
		

def main():

	global verbose  # explicitly declare as global variable, otherwise, each function regards as local. 

	usage() # number of argument check  

	inputPath = sys.argv[1]
	
	#print("* db2support path : " + inputPath + "\n")
	
	if "-v" in sys.argv or "--verbose" in sys.argv:
		verbose = True

	db2Level(inputPath)
	psList(inputPath)
	db2Node(inputPath)

if __name__ == "__main__":
    main()
