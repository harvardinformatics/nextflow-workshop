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

The path to this subdirectory is shown in truncated form in your terminal output, but by default only one representative directory is shown for each process. To see all the subdirectories for every process, you can run the nextflow command using the option `-ansi-log false`:

```
N E X T F L O W  ~  version 25.04.6
Launching `hello-nextflow-simple.nf` [kickass_brenner] DSL2 - revision: 733376c81e
[59/d5b161] Submitted process > sayHello (1)
[43/41749a] Submitted process > sayHello (2)
[19/ee5a79] Submitted process > sayHello (3)
[ab/e608e9] Submitted process > convertToUpper (3)
[30/9f5ed4] Submitted process > convertToUpper (1)
[c3/99715f] Submitted process > convertToUpper (2)
[28/51dd90] Submitted process > collectGreetings
There were 3 greetings in this batch
```

You can see that the `sayHello` process was run three times, and each time it created a subdirectory in the `work` directory. Let's look at one of these directories. `cd` to the subdirectory `work/59/d5b161` (press tab to complete the directory path), run `tree -a` and you should see something like this:

```bash
work/59/d5b1612cfe83377ed137f94c409c5d
├── .command.begin
├── .command.err
├── .command.log
├── .command.out
├── .command.run
├── .command.sh
├── .exitcode
└── Hello-output.txt
```

The files that begin with `.` are all helper or log files. The other files are the output files of the process. Occastionally you will also see input files that were staged for this process. Staged in this case means that the input files were symlinked to this directory so that the process can access them. 

Let's go over each of these dot files and what they contain:

* `.command.begin`: Metadata related to the beginning of the execution of the process call
* `.command.err`: Error messages (stderr) emitted by the process call
* `.command.log`: Complete log output emitted by the process call (Both stdout and stderr)
* `.command.out`: Regular output (stdout) by the process call
* `.command.run`: Full script run by Nextflow to execute the process call
* `.command.sh`: The command that was actually run by the process call
* `.exitcode`: The exit code resulting from the command

The `.command.sh` file tells you what command Nextflow actually ran. Any file name wildcards will be expanded into actual file names and parameters passed to the command line software call will also be fully parsed here. So this is a good place to start when you are debugging your nextflow workflow. When we get to the troubleshooting section, we will see how these files can be useful for debugging. 

Note: the word directory can be full very quickly, because each time you run a process, it creates a new subdirectory in the `work` directory. If you run the same process multiple times, it will create multiple subdirectories. We recommend setting the work directory to a scratch directory rather than your home or lab share so that it does not fill up your allocation. You should think of everything in the `work` directory as temporary files that can be deleted at any time.

### The `publishDir` directory

The `publishDir` directory is where nextflow puts output files that you want to save. Pipeline authors usually specify this directory in a configuration file, and sometimes it is an option that you can pass to the pipeline when you run it. In our case, the process `collectGreetings` is the last process in the workflow and it has a `publishDir` directive that specifies where the output files should be written. 

```groovy title="hello-nextflow-simple.nf" linenums="1"
process collectGreetings {
    publishDir 'results', mode: 'copy'
    
    input:
    path input_files

    output:
        path "COLLECTED-output.txt" , emit: outfile
        val count_greetings , emit: count

    script:
        count_greetings = input_files.size()
    """
    cat ${input_files} > 'COLLECTED-output.txt'
    """
}
```

Now, if we look into the `results` directory, we should see a file called `COLLECTED-output.txt` that contains all the greetings from the input CSV file, but capitalized. 

## Resuming a workflow

One of the best features of a workflow manager like nextflow is resumability. Resumability is the ability to restart a workflow from where it left off, rather than starting over from scratch. This is especially useful when running long-running workflows or when you want to make changes to a workflow without losing progress. Let's see how this works by modifying the input CSV file and resuming the workflow. Open the `greetings.csv` file in the `hello-nextflow-simple` directory and add a new greeting to the file, then save it. It should look something like this:

```csv
Hello
Bonjour
Holà
Aloha
```

Now, in your terminal, run the following command to resume the workflow:

```bash
nextflow run hello-nextflow-simple.nf -resume
```

```
 N E X T F L O W   ~  version 25.04.6

Launching `hello-nextflow-simple.nf` [special_engelbart] DSL2 - revision: 733376c81e

executor >  local (3)
[1d/9aa5d4] sayHello (4)       [100%] 4 of 4, cached: 3 ✔
[4a/393bdd] convertToUpper (4) [100%] 4 of 4, cached: 3 ✔
[28/6e6f32] collectGreetings   [100%] 1 of 1 ✔
There were 4 greetings in this batch
```

You can see that nextflow recognized that the first three greetings were already processed. The line "cached: 3" indicates that there were 3 process calls that nextflow did not need to run again. So it ran `sayHello` and `convertToUpper` for the new greeting and then had to rerun `collectGreetings` to collect all the greetings into one file. If you look in the `results` directory, you should see that the `COLLECTED-output.txt` file now contains the new greeting as well.

What kinds of modifications will trigger a rerun vs a cache? Here are some examples:

1. **Input file changes**: If you modify the input files (e.g., `greetings.csv`), nextflow will detect the changes and rerun the affected processes
2. **Process script changes**: Changing the script section of a process will affect that process and any downstream processes that depend on it. 
3. **Parameter changes**: If you change any parameters passed to a process (e.g., changing the `publishDir`), nextflow will rerun the process.
4. **Output file changes**: Deleting/modifying the output files (e.g., `COLLECTED-output.txt`)
5. **Work directory deletion**: If you delete the `work` directory, nextflow will rerun all processes because it has no record of what was previously run.

What are some modifications that will not trigger a rerun?

1. **Deleting irrelevant files**: If you delete work directory files that did not participate in the previous run, it will not affect the next run. For example, if you did a bunch of test runs on test data and then a production run on real data, deleting the work directories related to the test runs will not affect the production run.
2. **Adding new files**: If you add new files to the input directory that were not part of the previous run, nextflow will not rerun the previous processes, but it will run the new processes for the new files.

