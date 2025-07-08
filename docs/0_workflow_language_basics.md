## Workflow language basics

This section will introduce people to the concept of workflow langauges and their use. 

This section should take ~15 minutes and is mostly a presentation. 

### What is a bioinformatics workflow?

In biological data analysis, the raw files we work with tend to require some processing before it's able to be analyzed. In this simplified representation of an RNA-seq workflow, raw reads need to be quality controlled and mapped to a reference genome in order to produce a count table of reads.

In the manual way of running these workflows, you may have a separate sbatch script for each of these steps. You would submit it, wait for every file to complete, then submit the next step in the series. You may run into issues such as:

* A software not being installed properly causing the script to fail
* Malformed data causing some of the files to not complete
* A morass of log files to wade through to try and diagnose

Troubleshooting these issues and restarting your pipeline is annoying. A workflow language like nextflow can keep track of the softwares used, the state of where each piece of data is in the pipeline, and what the issues were, in order to have a smooth resumption of the workflow. It's also self-documenting and more reproducible than a folder of custom scripts that runs for just you.

### How does nextflow work?

* Head job orchestrate child jobs
* etc

