## Running nextflow locally

In this section we will go through running a few small jobs locally and examining how nextflow works. All of this will apply to running it on the HPC, but because we are not requiring students to have a Cannon account, we will run everything locally. 

This section should be the bulk of the 3 hour workshop (1.5 hours?)

### Run hello-nextflow-simple

Run hello-nextflow-simple

Learning goals

* Learn about the work directory and publish directory
* Learn about generally how a nextflow pipeline might look
* Learn about nextflow resume and how/why that works
    * and when it doesn't work!

Activities:

run hello-nextflow and look at the files that are generated. Look at the console output for the files.
look at the work directory.
run hello-nextflow again and look at the console output for the files.
delete one of the output files, add a new greeting in the csv and use nextflow resume.
delete the work directory and run nextflow resume.


### Run hello-config

hello-config is like hello-nextflow, except the user needs to specify an input csv and some parameters (like which specific tools to run)

Learning goals

* Brief digression about conda vs singularity
* Learn about editing config files
* Learn about running nextflow with parameters and the difference between workflow specific parameters and nextflow options
* Learn how to change compute resources for a specific task using either config or command line
* Run nextflow with report to generate resource utilization report

Activities:
Run hello nextflow using conda vs using singularity
Run hello nextflow with different amounts of cpus
Run hello nextflow with report

### Run hello-troubleshoot

Run hello-troubleshoot

There will be a few errors in the nextflow pipeline that a person will need to debug. Maybe there will be multiple nextflow runs to troubleshoot. 

Learning goals

* Learn to read the nextflow log and identify which process failed
* Learn to go to the work directory of the process and examine the output, exit code
* What are some common errors you might get?
* How to ask for help
* Where to ask for help

Activities:

TBD (What kind of errors are reasonable for them to troubleshoot? Maybe just stuff for )