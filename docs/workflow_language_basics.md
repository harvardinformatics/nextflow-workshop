## Workflow language basics

This section will introduce people to the concept of workflow langauges and their use. 

This section should take ~20-30 minutes and is mostly a presentation. 

### What is a bioinformatics workflow?

In biological data analysis, the raw files we work with tend to require some processing before it's able to be analyzed. In this simplified representation of an RNA-seq workflow, raw reads need to be quality controlled and mapped to a reference genome in order to produce a count table of reads.

In the manual way of running these workflows, you may have a separate sbatch script for each of these steps. You would submit it, wait for every file to complete, then submit the next step in the series. You may run into issues such as:

* A software not being installed properly causing the script to fail
* Malformed data causing some of the files to not complete
* A morass of log files to wade through to try and diagnose

Troubleshooting these issues and restarting your pipeline is annoying. A workflow language like nextflow can keep track of the softwares used, the state of where each piece of data is in the pipeline, and what the issues were, in order to have a smooth resumption of the workflow. It's also self-documenting and more reproducible than a folder of custom scripts that runs for just you.

## So you found a nextflow workflow...

This section maybe needs to be moved to after running_nextflow_locally so that people have more context.

### Evaluating third party nextflow workflows

When you find a third party nextflow workflow, it's important to evaluate whether this workflow will suit your needs. You need to determine:

1. What the inputs and outputs of the workflow are
2. What software the pipeline uses. Is it conda? is it docker/singularity?
3. What the configuration/parameter options are
4. The quality and completeness of the pipeline

For step number 4, here is what you want to look at:

* Does the pipeline have a separate docs page or just a github readme?
* When was the pipeline last updated or released?
* Does the pipeline account for deployment on different platforms, such as HPC and cloud?
* etc

Let's try to go through this process for a few example pipelines

Should we use seqera AI to help configure? Can it be used in the codespace?