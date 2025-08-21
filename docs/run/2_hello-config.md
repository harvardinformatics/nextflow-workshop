### Run hello-config

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