#!/bin/python

import os
import sys

infile = sys.argv[1]
outfile = sys.argv[2]
simple_dict = {}

f = open(infile)
firstline = f.readline()
for line in f:
	part1 = line.strip()
	parts = part1.split("\t")
	simple_dict[parts[0]] = parts[2]

f.close()

#print(simple_dict)

w = open(outfile, "w")
for k, v in simple_dict.items():
	if float(v) >= 30:
		w.write(f"{k}\n")
		print(f"bin {k} completness of {v}")

w.close()