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

### Software environments

Let's take a brief digression into talking about software environments, which is one of the configurable options of this pipeline. Good pipeline writers will include a couple of options for how to manage the software dependencies of their workflow. The two most common options are conda and docker/singularity. Conda is a package manager that allows you to create isolated environments with specific versions of software. Docker and Singularity are containerization technologies that allow you to package software and its dependencies into a single image that can be run on any system with the appropriate container runtime.


Conda:

* Package manager and environment management system
* Creates isolated environments with specific software versions
* Primarily used for Python/R packages but supports many languages
* Lightweight, shares system libraries

Docker:

* Containerization platform that packages applications with all dependencies
* Creates isolated containers with complete operating system environments
* Provides strong isolation and reproducibility
* Requires Docker daemon to run

Singularity:

* Container platform designed for HPC environments
* Compatible with Docker images but doesn't require root privileges
* Better suited for shared computing environments
* Can run Docker containers in HPC settings

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

## Using command line parameters to customize the workflow

When you run a nextflow workflow, any parameters that control how nextflow runs will be specified using a single dash `-` (e.g. if you want to resume a previous run, you would use `-resume`). However, any parameters that are specific to the workflow itself will be specified using two dashes `--`. In this workflow, there are several parameters that control which processes are run and where the input and output files are located. 

For example, you can try running the workflow with the following command:

```bash
nextflow run main.nf --samplesheet other_samplesheet.txt --input_dir data2 --outdir results2
```

By using the `--samplesheet`, `--input_dir`, and `--outdir` parameters, we have changed the input/output locations and changed the samplesheet parameter. If you look at the `main.nf` file, you can see that the parameters have defaults defined at the top of the file:

```groovy
params.samplesheet = "samplesheet.txt"
params.input_dir = "data"
params.outdir = "results"
params.run_lines = true
params.run_words = true
params.run_aggregate = true
```

These parameters can be overridden by specifying them on the command line using the `--` syntax. So for example, if we wanted to only run the `LINES` process and skip the `WORDS` and `AGGREGATE` processes and do so on our new input files, we could run the following command:

```bash
nextflow run main.nf --samplesheet other_samplesheet.txt --input_dir data2 --outdir results2 --run_words false --run_aggregate false
```

## Using parameter files to customize the workflow

Stringing multiple parameters together like this can get tedious, so there's a way to specify parameters in a file and then pass that file to nextflow using the `-params-file` option. In this workflow folder, the author has provided two additional files: `params.json` and `params-minimal.json`. These files contain parameters that can be used to customize the workflow.

## Running nextflow with reporting

When you run a nextflow workflow, you can generate various reports that summarize the execution of the workflow. These reports can be very useful for understanding the performance of your workflow and for debugging any issues that may arise. In this workflow, the author has configured the `nextflow.config` file to generate several reports by default. You can see these settings in the `nextflow.config` file:

```groovy
timeline {
    enabled = true
    overwrite = true
    file = "${params.outdir}/pipeline_info/execution_timeline.html"
}

report {
    enabled = true
    overwrite = true
    file = "${params.outdir}/pipeline_info/execution_report.html"
}

trace {
    enabled = true
    overwrite = true
    file = "${params.outdir}/pipeline_info/execution_trace.txt"
    fields = 'task_id,hash,native_id,process,tag,name,status,exit,module,container,cpus,time,disk,memory,attempt,submit,start,complete,duration,realtime,queue,%cpu,%mem,rss,vmem,peak_rss,peak_vmem,rchar,wchar,syscr,syscw,read_bytes,write_bytes'
}

dag {
    enabled = true
    file = "${params.outdir}/pipeline_info/pipeline_dag.svg"
}
```

Let's take a look at the `results/pipeline_info` directory now. You should see a few files describing the latest run of the workflow. Download the html files to your local machine by right clicking it and then open them in a web browser to see the report and timeline.

