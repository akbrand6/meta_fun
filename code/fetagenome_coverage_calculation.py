#!/bin/py

import argparse
import sys


def get_args(argv):

	parser = argparse.ArgumentParser(description="This script is meant to get the actual coverage calculation for the mock metagenomes through fetagenome. In this script are the lengths of the reference genomes used. Inputs should be the number of reads used and the numbers used in the config file.")

	group = parser.add_mutually_exclusive_group(required=True)

	group.add_argument('-r', '--reads', type=int, help="The number of reads used to generate the metagenome.")
	group.add_argument('-g', '--goal', type=int, help="Goal coverage (for example 40 for 40x) to calculate the required config file numbers.")

	parser.add_argument('-v', '--verbose', action="store_true", help="For suggestions or more details on how to change the config file if you do not want equal coverage for everything.")
	parser.add_argument('-i','--input_file', required = True, help = "A tsv file with headers, the headers must be \"species\", \"size\", \"config\".  the species and size are required, \"config\" is not, as you may need this script to generate the numbers for config. ")
	parser.add_argument('-L', '--Length', required=False, type=int, default=150, help = "Read length in Base Pairs. This is typically 150, default is 150, you can change it if desired.")

	return parser.parse_args(argv)


def read_input_file(infile):
	reference_dict = {}
	config_dict = {}
	f = open(infile)
	headers = f.readline().strip().split("\t")

	config_index = None
	if "config" in headers:
		config_index = headers.index("config")
	for line in f:
		parts = line.strip().split("\t")
		reference_dict[parts[0]] = int(parts[1])
		if config_index is not None:
			config_dict[parts[0]] = float(parts[config_index])
	
	f.close()


	return reference_dict, config_dict

def calc_avg_coverage(reference_dict, num_reads, read_length):


	### 	In the Illumina equation C = LN/G  
	### L = read length (in bp) — per read if N is number of reads, or per pair if N is number of pairs 
	### N = number of reads ........ or number of read pairs. 

	G = sum(reference_dict.values())
	L = read_length
	N = num_reads


	average_coverage = round((L*N)/G,2)


	return average_coverage




def calc_individual_coverage(reference_dict, config_dict, num_reads, read_length):

	if len(config_dict) == 0:
		sys.exit(f"\"config\" must be the third column of your input tsv.\n \nTo get the values needed here, try the -g flag with the argument of the goal coverage. \nThis will tell you how many reads, and the values you should use in your configuration file.\n")
	else:
		coverage_dict = {}
		reads_dict = {}
		coverage_proportion = sum(config_dict.values())

		for key, value in config_dict.items():
			reads_dict[key] = round(((config_dict[key]/coverage_proportion) * (num_reads))) # times two because we need forward and reverse.

		for key, value in reads_dict.items():
			coverage_dict[key] = round((read_length * reads_dict[key])/(reference_dict[key]))


	return coverage_dict




def calculate_function(goal_coverage, reference_dict, verbose, read_length):
	# as a reminder to myself. Reference dict is the species, and the genome length.  
	# So we know that for each species, the G, is found in reference dict.  L is length(150), C is the goal coverage. 
	

	num_reads_dict = {}
	config_dict = {}

	for key, value in reference_dict.items():
		num_reads_dict[key] = round((goal_coverage * reference_dict[key])/read_length)

	#print(num_reads_dict)
	print(f"The total number of reads per species to get {goal_coverage}x coverage is:")
	for sub in num_reads_dict.keys():
		print(f"{sub} needs \t{num_reads_dict[sub]} reads.")

	sum_reads = sum(num_reads_dict.values())
	print(f"\nFor a total number of reads of {sum_reads}")

	for key, value in num_reads_dict.items():
		config_dict[key] = num_reads_dict[key]/sum_reads
	print(f"\nThe configuration file should have these values:")
	for sub in config_dict.keys():
		print(f"{sub} = \t{config_dict[sub]}")

	if verbose:
		print(f"\n\nIf you want to do something weird like double the number of reads for bacteria, then just double the associated number from the config file, and also add that associated number of reads.")
		aa = list(config_dict.keys())[0]
		print(f"\nFor example. to double {aa}, you would want {config_dict[aa]*2} in the config file, and {num_reads_dict[aa]} reads added to the sum of reads, in this case total reads would pop up to {sum_reads + num_reads_dict[aa]}")
	return config_dict




def main(argv=None):

	args = get_args(argv)

	# Reference_dict is the name of the reference geneome, and the number of bases.  The coverage dict must match
	#reference_dict = {'Bacillus subtillis': 4268302, 'Klebsiella varicola': 5590209, 'Candida albicans': 14461203, 'hanseniaspora uvarum': 8990414, 'Pichia terricola': 12694429}
	#config_dict = {'Bacillus subtillis': 1, 'Klebsiella varicola':1, 'Candida albicans': 0.5, 'hanseniaspora uvarum': 0.5, 'Pichia terricola': 0.5}
	#config_dict = {'Bacillus subtillis': 0.09277999250400354, 'Klebsiella varicola':0.12151421084747963, 'Candida albicans': 0.31434276919194365, 'hanseniaspora uvarum': 0.1954244424587716, 'Pichia terricola': 0.27593858499780155}

	reference_dict, config_dict = read_input_file(args.input_file)



	if args.goal is not None:
		calculate_function(args.goal, reference_dict, args.verbose, args.Length)


	else:
		average_coverage = calc_avg_coverage(reference_dict, args.reads, args.Length)

		actual_reads_dict = calc_individual_coverage(reference_dict, config_dict, args.reads, args.Length)

		print(f"The coverage for each species in entire metagenome is:")
		for sub in actual_reads_dict.keys():
			print(f"{sub} = {actual_reads_dict[sub]}x coverage.")

		print(f"\nWith an average coverage of {average_coverage}.")

	return 0




if __name__ == "__main__":
	main()
