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

## Run nextflow-simple

In this section, we will be running a small nextflow workflow that converts a list of greetings into separate files of uppercase greetings. Navigiate to the `01-nextflow-simple` folder and open the `README.md` file. This is what a typical README file for a third-party nextflow workflow might look like. It has a description of the inputs and outputs of the pipeline, installation instructions, and usage instructions. 

### The process definition

Now let's take a quick look at the `main.nf` file in this folder. We won't go over too much of the details, but we do want to understand the general structure of a nextflow file. Nextflow scripts have two main components, **processes** and the **workflow**. Let's first look at the **process** block. 

```groovy title="main.nf" linenums="1"
#!/usr/bin/env nextflow

/*
    * A process to count lines in text files
    * for a list of samples provided in a sample sheet.
*/
process COUNT_LINES {
    conda "conda-forge::gawk=5.1.0"
    
    input:
    tuple val(sample_id), path(input_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.lines"), emit: lines

    script:
    """
    wc -l ${input_file} | awk '{print \$1}' > ${sample_id}.lines
    """
}
```

The process block represents a single step in the overall workflow. You can think of a process as a function that takes an input and generates an output. Processes are defined at the level of a single instance of a task. This process, called `COUNT_LINES`, has an input, and output, and a script. The purpose of `COUNT_LINES` is to count the number of lines in a text file and save it in a file called `<sample_id>.lines`, where `<sample_id>` is the ID of the sample being processed.

### The workflow definition

Now let's look at the bottom part of the `main.nf` file, the **workflow** definition. 

```groovy title="main.nf" linenums="1"
/*
    * The main workflow definition
*/
workflow {
    // Create input channel from sample sheet
    samples_ch = Channel
        .fromPath(params.samplesheet)
        .splitText()
        .map { it.trim() }
        .map { sample -> tuple(sample, file("${params.input_dir}/${sample}.txt")) }
    
    // Run processes
    COUNT_LINES(samples_ch)
    COUNT_WORDS(samples_ch)
    
    // Join the outputs and combine counts
    combined_ch = COUNT_LINES.out.join(COUNT_WORDS.out)
    COMBINE_COUNTS(combined_ch)
    
    // Collect and aggregate all results
    AGGREGATE(COMBINE_COUNTS.out.collect { it[1] })
}
```

The workflow portion of the nextflow file is where the processes are activated. As you can see, the `COUNT_LINES` process is called in a similar fashion to a function. The outputs of the `COUNT_LINES` and `COUNT_WORDS` processes are joined together and passed to the `COMBINE_COUNTS` process. The output of `COMBINE_COUNTS` is then collected and passed to the `AGGREGATE` process.

## Running the workflow

Now let's run the workflow according to the instructions on the README. In your terminal, run the following command:

```bash
nextflow run main.nf
```

Your console output should look something like this:

```title="Output" linenums="1"
 N E X T F L O W   ~  version 25.04.3

Launching `main.nf` [friendly_hamilton] DSL2 - revision: ac7cb7041c

executor >  local (7)
[3b/a692a0] COUNT_LINES (2)    [100%] 2 of 2 ✔
[16/7f8faa] COUNT_WORDS (1)    [100%] 2 of 2 ✔
[f3/359516] COMBINE_COUNTS (2) [100%] 2 of 2 ✔
[46/cf1828] AGGREGATE          [100%] 1 of 1 ✔
```

The important part of this output are the process lines, which tells you which processes were run, which how many suceeded, and where to find the **work directory** of the process call. Let's look at the result of the `COUNT_LINES` nextflow process.

### Examining the `work` directory

When you run Nextflow for the first time in a directory, it creates a directory called `work` where it will stage and write all files generated in the course of execution. Within the work directory, each instance of a process gets its own subdirectory, named with a hash in order to make it unique. Within this subdirectory, Nextflow stages inputs, writes helper files, writes out any logs, executes the script, and creates the output files for that process. 

The path to this subdirectory is shown in truncated form in your terminal output, but by default only one representative directory is shown for each process. To see all the subdirectories for every process, you can run the nextflow command using the option `-ansi-log false`:

```
N E X T F L O W  ~  version 25.04.3
Launching `main.nf` [furious_swanson] DSL2 - revision: d216eb5f95
[ab/75a135] Submitted process > COUNT_WORDS (2)
[6d/c955dc] Submitted process > COUNT_LINES (2)
[80/aa9673] Submitted process > COUNT_LINES (1)
[0b/5dc796] Submitted process > COUNT_WORDS (1)
[f4/cf765e] Submitted process > COMBINE_COUNTS (2)
[78/bd8579] Submitted process > COMBINE_COUNTS (1)
[56/867990] Submitted process > AGGREGATE
```

You can see that the `COUNT_LINES` process was run two times, and each time it created a subdirectory in the `work` directory. Let's look at one of these directories. `cd` to the subdirectory **that appears in your own terminal** corresponding to one of the COUNT_LINES processes (press tab to complete the directory path), run `tree -a` and you should see something like this:

```bash
training/run/01-nextflow-simple/work/80/aa96730e803bfa2cf68af15b6a09c3 -> tree -a
.
├── .command.begin
├── .command.err
├── .command.log
├── .command.out
├── .command.run
├── .command.sh
├── .exitcode
├── sample1.lines
└── sample1.txt -> /path/to/nextflow_workshop/run/01-nextflow-simple/data/sample1.txt
```

The files that begin with `.` are all helper or log files. The `sample1.lines` file is the output file of the process. You can also see input files that were staged for this process. Staged in this case means that the input files were symlinked to this directory so that the process can access them. So the `sample1.txt` file is a symlink to the actual input file in the `data` directory.

Let's go over each of these dot files and what they contain:

* `.command.begin`: Metadata related to the beginning of the execution of the process call
* `.command.err`: Error messages (stderr) emitted by the process call
* `.command.log`: Complete log output emitted by the process call (Both stdout and stderr)
* `.command.out`: Regular output (stdout) by the process call
* `.command.run`: Full script run by Nextflow to execute the process call
* `.command.sh`: The command that was actually run by the process call
* `.exitcode`: The exit code resulting from the command

The `.command.sh` file tells you what command Nextflow actually ran. Any file name wildcards will be expanded into actual file names and parameters passed to the command line software call will also be fully parsed here. So this is a good place to start when you are debugging your nextflow workflow. When we get to the troubleshooting section, we will see how these files can be useful for debugging. 

Note: the work directory can be full very quickly, because each time you run a process, it creates a new subdirectory in the `work` directory. If you run the same process multiple times, it will create multiple subdirectories. We recommend setting the work directory to a scratch directory rather than your home or lab share so that it does not fill up your allocation. You should think of everything in the `work` directory as temporary files that can be deleted at any time.

### The `publishDir` directory

The `publishDir` directory is where nextflow puts output files that you want to save. Pipeline authors usually specify this directory in a configuration file, and sometimes it is an option that you can pass to the pipeline when you run it. In our case, the process `AGGREGATE` is the last process in the workflow and it has a `publishDir` directive that specifies where the output files should be written. At the top of the `main.nf` file, you can see that the default output directory is set to `results`.

```groovy title="main.nf" linenums="1"
/*
    * A process to aggregate all summary files
    * into a single TSV file.
*/
process AGGREGATE {
    conda "conda-forge::gawk=5.1.0"

    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    path summary_files
    
    output:
    path "aggregate-summary.tsv"

    script:
    """
    echo -e "sample\tlines\twords" > aggregate-summary.tsv
    for summary_file in ${summary_files}; do
        SAMPLE_NAME=\$(basename "\$summary_file" .summary)
        LINES=\$(grep -e "^lines\t" "\$summary_file" | cut -f2)
        WORDS=\$(grep -e "^words\t" "\$summary_file" | cut -f2)
        echo -e "\$SAMPLE_NAME\t\$LINES\t\$WORDS" >> aggregate-summary.tsv
    done
    """
}
```

Now, if we look into the `results` directory, we should see a file called `aggregate-summary.tsv` that contains all the information from the individual summary files, but in one place.

## Resuming a workflow

One of the best features of a workflow manager like nextflow is resumability. Resumability is the ability to restart a workflow from where it left off, rather than starting over from scratch. This is especially useful when running long-running workflows or when you want to make changes to a workflow without losing progress. Let's see how this works by modifying the `samplesheet.txt` file and resuming the workflow. Open the `samplesheet.txt` file in the `01-nextflow-simple` directory and add a new sample to the file (`sample3`), then save it. It should look something like this:

```csv
sample1
sample2
sample3

```

Now, in your terminal, run the following command to resume the workflow:

```bash
nextflow run main.nf -resume
```

```
 N E X T F L O W   ~  version 25.04.3

Launching `main.nf` [astonishing_faggin] DSL2 - revision: d216eb5f95

executor >  local (4)
[6e/e0043f] COUNT_LINES (3)    [100%] 3 of 3, cached: 2 ✔
[c0/f6fbab] COUNT_WORDS (3)    [100%] 3 of 3, cached: 2 ✔
[64/2ba6fc] COMBINE_COUNTS (3) [100%] 3 of 3, cached: 2 ✔
[47/b75dec] AGGREGATE          [100%] 1 of 1 ✔
```

You can see that nextflow recognized that the first two samples were already processed. The line "cached: 2" indicates that there were 2 process calls that nextflow did not need to run again. So it ran `COUNT_LINES`, `COUNT_WORDS`, and `COMBINE_COUNTS`, for the new greeting and then had to rerun `AGGREGATE` to collect all the counts into one file. If you look in the `results` directory, you should see that the `aggregate-summary.tsv` file now contains the new sample as well.

What kinds of modifications will trigger a rerun vs a cache? Here are some examples:

1. **Input file changes**: If you modify the input files (e.g., `sample1.txt` or `samplesheet.txt`), nextflow will detect the changes and rerun the affected processes
2. **Process script changes**: Changing the script section of a process will affect that process and any downstream processes that depend on it. 
3. **Parameter changes**: If you change any parameters passed to a process (e.g., changing the `publishDir`), nextflow will rerun the process.
4. **Output file changes**: Deleting/modifying the output files (e.g., `aggregate-summary.tsv`)
5. **Work directory deletion**: If you delete the `work` directory, nextflow will rerun all processes because it has no record of what was previously run.

What are some modifications that will not trigger a rerun?

1. **Deleting irrelevant files**: If you delete work directory files that did not participate in the previous run, it will not affect the next run. For example, if you did a bunch of test runs on test data and then a production run on real data, deleting the work directories related to the test runs will not affect the production run.
2. **Adding new files**: If you add new files to the input directory that were not part of the previous run, nextflow will not rerun the previous processes, but it will run the new processes for the new files.

