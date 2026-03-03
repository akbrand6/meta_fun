#!/bin/bash
#SBATCH --job-name=meta_fun
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=60:00:00
#SBATCH --error ./logs/meta_fun.e%j
#SBATCH --output ./logs/meta_fun.o%j
#SBATCH --no-requeue


# Define directories
                                                                                            ## Update work dir path
work_dir="<path_to_work_directory>/workflow-output/work"

# Initialize Nextflow environment
                                                                                            ## These may need to be updated for proper Java version, based on your cluster setup.
export JAVA_HOME=/usr/lib/jvm/java-24-openjdk
export PATH=$JAVA_HOME/bin:$PATH
                                                                                            ## update path to where your nextflow executable is
export PATH="<path_to_nextflow_executable>/:$PATH"
export NXF_OPTS="-Xms500M -Xmx2G"
export NXF_ANSI_LOC=false
export NXF_CONDA_ENABLED=true
export NXF_EXECUTOR=slurm
export NXF_WORK=${work_dir}



# Initiate Nextflow job

nextflow -c meta_Fun.conf -log ./logs/nextflow.log run meta_Fun.nf -profile FNWI -resume --with-trace
