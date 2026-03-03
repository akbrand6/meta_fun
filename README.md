# meta_fun
## A nextflow pipeline for fungal metagenomic generation of MAGs

This pipeline is intended to work directly with the output of IMP3 after assembly. 

Using whokaryote+Tiara, the eukaryotic contigs are identified and selected for binning (with concoct). After binning, quality is checked with BUSCO, and bins that reach the quality minimum of 30% are passed along for taxanomic identification with kaiju, and the eukdetect database. 

## Setup
After cloning this repository there will be a few paths that need to be changed.  

### Paths that will need to be changed for every run:
- meta_Fun.sh
    - work_dir path
- meta_Fun.conf
    - workflow_output path
    - workflow path (The input location, where all scripts and the nextflow-readfile.csv are)
    - nextflow-readfile.csv (The actual samples to be run. edit this file to tell nextflow the names and locations of your samples.)

### Paths that need to be set up before the first run
- meta_Fun.sh
    - Possibly Java location (based on cluster setup)
    - Path to nextflow executable
- meta_Fun.Conf
    - path to conda.sh (So nextflow can activate conda envs)
    - params.busco_DB = path_to_busco_database
    - kaiju_database_path = path_to_kaiju_nr_euk_database (please double check the complete path for the three subsequent lines are correct)
- meta_Fun.nf
    - For each process, the first line is the location of the conda env.  These will **all** need to be updated before use.


I assume a slurm based cluster.  There are a few small things that would need to be changed for other cluster executors. Things like
- batch codes in meta_Fun.sh
- executor and job management executor in meta_Fun.conf


## Usage

An input of assembled contigs will take highly variable amounts of time based on the number and size of the contigs. 
The output is directly dependant on the depth of coverage. The lowest average depth recoverable is 5x, but this only happened in small mock communities of few fungi. 
**Anything with an average depth of 6x or more should complete.**

A completed bin will have an attempt at taxanomic classification with Kaiju, and bowtie2 compared to eukdetect database.
The results here are ... typically not completely clear. I personally use these results to make a custom kraken database with each of the top possibilities, and from there get a much more clear answer as to what my fungi actually is. 

The bin itself is, of course, a fasta file of this fungi. 



___
The code could easily be adapted to work with metagenomic assemblies done through other means. 

Two ways to do this:
1. Make a directory named "Assembly" and rename your multi fasta assembly to "mg.assembly.merged.fa" and your bam file to "mg.reads.sorted.bam" (and of course index it)
2. Change the names of the files the meta_Fun.nf under the process whokaryote, changing the names of the fasta and bam files where appropraite. 

