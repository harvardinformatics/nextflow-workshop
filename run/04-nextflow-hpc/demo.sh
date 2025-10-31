#!/bin/bash
#SBATCH -c 1                # Number of cores (-c)
#SBATCH -t 0-01:00          # Runtime in D-HH:MM, minimum of 10 minutes
#SBATCH -p shared           # Partition to submit to
#SBATCH --mem=8G           # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH -o nf_job_%j.out    # File to which STDOUT will be written, including job ID
 
# need to load the java & python modules
module load jdk
module load python

# Run nextflow
nextflow run nf-core/demo -profile cannon,test,singularity -with-report -with-timeline -with-trace -with-dag results/pipeline_info/pipeline_dag.svg
