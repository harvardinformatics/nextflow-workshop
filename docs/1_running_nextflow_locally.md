# OUTLINE

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

## Running nextflow locally

In this section we will go through running a few small jobs locally and examining how nextflow works. All of this will apply to running it on the HPC, but because we are not requiring students to have a Cannon account, we will run everything locally. 

This section should be the bulk of the 3 hour workshop (1.5 hours?)

## Run hello-nextflow-simple

In this section, we will be running a small nextflow workflow that converts a list of greetings into separate files of uppercase greetings. Navigiate to the `hello-nextflow-simple` folder and open the `README.md` file. This is what a typical README file for a third-party nextflow workflow might look like. It has a description of the inputs and outputs of the pipeline, installation instructions, and usage instructions. 

### The process definition

Now let's take a quick look at the `hello-nextflow-simple.nf` file in this folder. We won't go over too much of the details, but we do want to understand the general structure of a nextflow file. Nextflow scripts have two main components, **processes** and the **workflow**. Let's first look at the **process** block. 

```groovy title="hello-nextflow-simple.nf" linenums="1"
#!/usr/bin/env nextflow

/*
 * Use echo to print 'Hello World!' to a file
 */
process sayHello {

    input:
        val greeting

    output:
        path "${greeting}-output.txt"

    script:
    """
    echo '$greeting' > '$greeting-output.txt'
    """
}
```

The process block represents a single step in the overall workflow. You can think of a process as a function that takes an input and generates an output. Processes are defined at the level of a single instance of a task. This process, called `sayHello`, has an input, and output, and a script. The purpose of `sayHello` is to take a greeting, such as `Hello`, and save it in a file called `Hello-output.txt`.

### The workflow definition

Now let's look at the bottom part of the `hello-nextflow-simple.nf` file, the **workflow** definition. 

```groovy title="hello-nextflow-simple.nf" linenums="1"
workflow {

    // create a channel for inputs from a CSV file
    greeting_ch = Channel.fromPath(params.greeting)
                        .splitCsv()
                        .map { line -> line[0] }

    // emit a greeting
    sayHello(greeting_ch)

    // convert the greeting to uppercase
    convertToUpper(sayHello.out)

    // collect all the greetings into one file
    collectGreetings(convertToUpper.out.collect(), params.batch)

    // emit a message about the size of the batch
    collectGreetings.out.count.view { "There were $it greetings in this batch" }

    // optional view statements
    //convertToUpper.out.view { "Before collect: $it" }
    //convertToUpper.out.collect().view { "After collect: $it" }
}
```

The workflow portion of the nextflow file is where the processes are activated. As you can see, the `sayHello` process is called similar to a function. The outputs of the `sayHello` process are then passed to the next step, which is the `convertToUpper` process. 

## Running the workflow

Now let's run the workflow according to the instructions on the README. In your terminal, run the following command:

```bash
nextflow run main.nf
```

Your console output should look something like this:

```title="Output" linenums="1"
 N E X T F L O W   ~  version 24.10.4

Launching `main.nf` [goofy_mayer] DSL2 - revision: 7924362939

executor >  local (7)
[c4/093240] process > sayHello (2)       [100%] 3 of 3 ✔
[f1/f9da1a] process > convertToUpper (2) [100%] 3 of 3 ✔
[8b/bd8116] process > collectGreetings   [100%] 1 of 1 ✔
There were 3 greetings in this batch
```

The important part of this output are the process lines, which tells you which processes were run, which how many suceeded, and where to find the **work directory** of the process call. Let's look at the result of the `sayHello` nextflow process.

### Examining the `work` directory

When you run Nextflow for the first time in a directory, it creates a directory called `work` where it will stage and write all files generated in the course of execution. Within the work directory, each instance of a process gets its own subdirectory, named with a hash in order to make it unique. Within this subdirectory, Nextflow stages inputs, writes helper files, writes out any logs, executes the script, and creates the output files for that process. 

The path to this subdirectory is shown in truncated form 