# OUTLINE

hello-config is like hello-nextflow, except the user needs to specify an input csv and some parameters (like which specific tools to run)

Learning goals

* Brief digression about conda vs singularity
    * Definition of conda, docker, and singularity
    * Nextflow helps you manage software dependencies and environments
    * You need to be aware of how the author of the workflow has specified the environment
* Learn about editing config files
    * hello-config.nf can be run using conda or docker
* Learn about running nextflow with parameters and the difference between workflow specific parameters and nextflow options
* Learn how to change compute resources for a specific task using either config or command line
* Run nextflow with report to generate resource utilization report

Activities:
Run hello nextflow using conda vs using docker
Run hello nextflow with different amounts of cpus
Run hello nextflow with report

## Same workflow with more options

Often times, you will find in the instructions for a nextflow workflow that you will need to provide a configuration file or some parameters. This is because the workflow author has made the workflow more flexible and customizable. In this version of the workflow, we have the same processes as before, but there are some additional files that the author has provided. The README.md file is also a bit different and contains more information on how to customize the workflow.

Let's take a brief digression into talking about software environments, which is one of the configurable options of this pipeline. Good pipeline writers will include a couple of options for how to manage the software dependencies of their workflow. The two most common options are conda and docker/singularity. Conda is a package manager that allows you to create isolated environments with specific versions of software. Docker and Singularity are containerization technologies that allow you to package software and its dependencies into a single image that can be run on any system with the appropriate container runtime.

Summary:

Conda:

    Package manager and environment management system
    Creates isolated environments with specific software versions
    Primarily used for Python/R packages but supports many languages
    Lightweight, shares system libraries

Docker:

    Containerization platform that packages applications with all dependencies
    Creates isolated containers with complete operating system environments
    Provides strong isolation and reproducibility
    Requires Docker daemon to run

Singularity:

    Container platform designed for HPC environments
    Compatible with Docker images but doesn't require root privileges
    Better suited for shared computing environments
    Can run Docker containers in HPC settings

Let's look at the `cowpy` process for how depencies are specified:

```groovy
process COWPY {
    publishDir "${params.outdir}", mode: 'copy'
    container 'community.wave.seqera.io/library/pip_cowpy:8b70095d527cd773'
    conda 'conda-forge::cowpy==1.1.5'
    
    input:
    val samples_processed

    output:
    path "cowpy-output.txt"

    script:
    MESSAGE="Workflow completed! Samples processed: ${samples_processed.join(', ')}"
    """
    echo $MESSAGE | cowpy > cowpy-output.txt
    """
}
```

In this process, you can see that both a `container` and a `conda` environment are specified. This means that the user can choose to run the workflow using either conda or docker/singularity. The container link is a pre-built wave container (like a docker container) that has cowpy installed, while the conda line specifies that cowpy version 1.1.5 should be installed from the conda-forge channel.

The file `nextflow.config` contains lines that specify the default profile to use (docker) and the conda environment file to use if the user chooses the conda profile. The user can switch between these two options by using the `-profile` flag when running nextflow.

```json
profiles {
    conda {
        conda.enabled = true
    }
    
    docker {
        docker.enabled = true
        process {
            container = 'ubuntu:20.04'
        }
    }

 }
```

Let's first run the workflow using docker (the default):

```bash
nextflow run main.nf
```

Now let's run the workflow using conda:

```bash
nextflow run main.nf -profile conda
```

You will see that the workflow creates a conda environment in the work directory and installs cowpy into that environment. This temporary conda environment will be cached and reused for future runs of the workflow. 

## Using parameter files to customize the workflow

In this workflow folder, the author has provided two additional files: `params.json` and `params-minimal.json`. These files contain parameters that can be used to customize the workflow. For example, you can choose which processes to run by setting the `run_lines`, `run_words`, and `run_aggregate` parameters to true or false. Any of these parameters can be specified on the command line using two dashes `--`, but it is better practice to use a parameter file when there are many parameters to set.


