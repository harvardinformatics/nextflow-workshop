---
title: "[Workshop] Writing Nextflow Workflows"
authors:
    - Lei Ma
    - Danielle Khost
author_header: Workshop Developers
---

# Nextflow Workshop, part 2: Writing workflows

## Introduction

Welcome to the second part of our Nextflow workshop! In this section, we will learn how to begin creating a Nextflow workflow from a series of shell scripts. We will learn about what types of workflows might benefit from being converted to Nextflow, how to go from a series of shell scripts to a pipeline, and how to make a pipeline configurable so that it can be used with different datasets. Keep in mind that this session is designed to give you a taste of developing Nextflow workflows, and uses a very simple example. If you want assistance with turning your own workflow into a Nextflow workflow, please reach out to us for help!

!!! warning "Run `git pull` at the beginning of the workshop"

    Because we have been making changes to the workshop content, if you have cloned the [workshop repository :octicons-link-external-24:](https://github.com/harvardinformatics/nextflow-workshop){ target="_blank" }  before today, please run `git pull` in the root directory of the repository to make sure you have the latest version of the materials. If you downloaded the materials as a zip file, please redownload the zip file and extract it again.

## What workflows are suitable for Nextflow?

Although we love workflow managers like Nextflow, that doesn't mean that every single time we're running something on our computers we are wrapping them in a Nextflow script. A workflow manager has the following powerful features:

* **Resumability**: If a step in a workflow fails, you can rerun from that step.
* **Reproducibility**: You can rerun the same workflow with the same input data and get the same results.
* **Parallelization**: You can run multiple steps in parallel, and subsequent steps run without waiting for unrelated steps to finish.
* **Scalability**: Running the same workflow for 1 or 100 files is the same

However, there is a good amount of overhead involved in writing a Nextflow pipeline, so in order to take advantage of these features, you may also ask whether your workflow has some of the following characteristics:

* **Multiple, interrelated steps**: If you have multiple file transformations that depend on each other, this is a good candidate for Nextflow. Don't use Nextflow if you have just one or two simple steps that are easily launched in a shell script.
* **Need for reruns**: If you need to rerun the same steps with different parameters (e.g. for benchmarking), or if you need to compare the results of different runs, Nextflow could help make this easier and more reproducible.
* **Can benefit from simple parallelization**: You have many independent steps that can be run in parallel, such as multiple input files to be processed with the same steps
* **Complex dependencies across steps**: Each process in Nextflow can run in a different environment, so this would be useful if you want to compartmentalize your software environments

A classic example of a workflow that would NOT be worth converting into a Nextflow workflow is some one-off exploratory or data cleaning script that you aren't sure you will ever run again. Another example is a super convoluted workflow that you don't fully understand or didn't write yourself, and don't have time to debug. In that case it might be better to just start fresh rather than trying to convert. 

## Should you write a Nextflow workflow or a Snakemake workflow?

Some of you may have taken our Snakemake workshop, or have experience with Snakemake already. Both Nextflow and Snakemake are powerful workflow managers, and both have their strengths and weaknesses. Here are some considerations to help you decide which one to use:

| Snakemake | Nextflow |
|-----------|----------|
| Written in python | Written in Groovy (Java)
| Syntax is simpler | More complicated syntax
| Simpler features -> easier to debug | More features -> harder to debug
| Used frequently in academia | Used frequently in industry
| Smaller userbase/community | Larger userbase/community
| Worse documentation & training | Better documentation & training
| modules (decentralized and not maintained) | nf-core (centrally curated and maintained)

In summary, in our opinion it is easier to get started with Snakemake, but Nextflow offers more powerful features and a larger community for support. Additionally, Snakemake the software is not developed as thoughtfully as Nextflow, often introducing breaking changes across versions, so it may be more difficult to maintain Snakemake workflows in the long term. However, Nextflow is more difficult to learn initially and it is run by a commercial entity (Seqera Labs). If you write a workflow in either Snakemake or Nextflow, you will be well positioned to convert it to the other workflow manager in the future if needed.

## Converting shell scripts to Nextflow workflows

### Drawing your own rulegraph

Planning ahead is important when writing a Snakemake workflow. Before you start writing any code, you should understand the relationships between the different steps in your workflow. One way to do this is to visualize the rulegraph of your workflow manually.

> **Exercise:** Read through the shell script files in the `shell-scripts` directory. These scripts take a set of text files in the `data` directory, count the number of lines and words in each file, and then combine those counts into a summary file for each input file. Draw a diagram of the input-output relationships of these scripts. For example, you might draw something like this:

```
data/sample1.txt  -->  01_count_lines.sh  -->  results/sample1.lines
```

> Or it may be easier to draw on paper.

### Understanding Nextflow channels

Let's take a look at how we can read in the samplesheet using Nextflow channels. Channels are a core concept in Nextflow, and they are used to pass data between processes. A channel can be thought of as a stream of data that can be consumed by one or more processes. Imagine a channel as a bucket or a conveyer belt that holds data. You can manipulate and order the data in a channel using various operators provided by Nextflow.

Channels are a powerful but difficult concept in Nextflow that doesn't really have any analog in other programming that we've seen before. The reason Nextflow has channels is so that users can do complex file manipulations and pass data between processes without having to write processes to take care of these low-level non-computational tasks. Unlike Snakemake, Nextflow does not operate solely on files, but rather on streams of data that can be files or other types of data, so channels are how data flow is managed. 

Let's learn how to create a channel that reads in the input `samplesheet.txt` file and prints out each line. Create a new file called `01_read_samplesheet.nf` and add the following code:

```nextflow
#!/usr/bin/env nextflow

workflow {
    // Create a channel that reads in the samplesheet
    samples = Channel.fromPath('samplesheet.txt')
        .splitText()
        .map { sample -> sample.trim() }
    
    // Print out each line in the samplesheet
    samples.view()
}
```

In nextflow syntax, the `.` indicates that we are calling an operator on the channel created in the previous line. Here, we create a channel using the `Channel.fromPath()` operator, which reads in the file at the specified path. We then use the `.splitText()` operator to split the text file into lines, creating a channel of lines. This channel of lines is assigned to the variable `samples`. Finally, we use the `.view()` operator to print out each item in the channel.

??? example "Command breakdown"

    | Command | Description |
    |---------|-------------|
    | `Channel.fromPath('samplesheet.txt')` | Creates a channel from the file path `samplesheet.txt` |
    | `.splitText()` | Splits the text file into lines and creates a channel of lines |
    | `.map { sample -> sample.trim() }` | Trims whitespace from each line in the channel (removes the newline character at the end) |
    | `samples.view()` | Prints out each item in the channel |

#### Channel factories

The `.fromPath()` is an example of a channel factory, which is a special type of operator that creates a new channel. You can think of these as different shapes of buckets or conveyer belts that hold data, with each one having some specialized way of treating the data. 

Here are some other [channel factories](https://nextflow.io/docs/latest/reference/channel.html) you might find useful:

| Factory | Description |
|---------|-------------|
| `Channel.fromPath('path/to/file')` | Creates a channel from a file path |
| `Channel.fromFilePairs('data/*.fastq')` | Creates a channel of file pairs based on a glob pattern, and files are emitted as tuples where the first item is the common prefix and the second item is the list of two fastq files |
| `Channel.of(item1, item2, item3)` | Creates a channel from a list of items |
| `Channel.fromList([item1, item2, item3])` | Creates a channel from a list |
| `Channel.fromSRA(['SRA_ACCESSION1', 'SRA_ACCESSION2'])` | Creates a channel from a list of SRA accessions and returns the FASTQ files matching the accessions|

Besides using factories, processes also emit data in the form of channels. Usually, you will be using channels created by processes rather than creating channels from factories directly. The exception is when you are reading in input data, such as in the example above.

**Exercise:** Try modifying the code above to use `Channel.fromList()` instead of `Channel.fromPath()`. You can create a list of strings that represent the lines in the samplesheet, and see if you can get the same output.

??? example "Solution"

    ```nextflow
    #!/usr/bin/env nextflow

    workflow {
        // Create a channel from a list of strings
        samples = Channel.fromList([
            'sample1',
            'sample2',
            'sample3'
        ])
        
        // Print out each line in the samplesheet
        samples.view()
    }
    ```

#### Channel operators

We've already seen a few channel operators in the code above: `.splitText()`, `.map{}`, and `.view()`. Here are some other common channel operators you might find useful:

| Operator | Description |
|----------|-------------|
| `combine()` | Emit the combination of two channels |
| `splitText()` | Splits a text file into lines and creates a channel of lines
| `map {}` | Transforms each item in the channel using a closure |
| `filter {}` | Filters items in the channel based on a condition |
| `collect()` | Collects all items in the channel into a list |
| `view()` | Prints out each item in the channel |

For a full list of channel operators see the [Nextflow documentation :octicons-link-external-24:](https://www.nextflow.io/docs/latest/reference/operator.html#operator-page){ target="_blank" }.

Operators can use either `{}` or `()` at the end. Operators use `{}` to define a **closure**, which is a custom logical expression. Operators that use `()` only do not require a closure but can take **arguments** inside the parentheses. For example the `.map {}` operator requires a closure to define how to transform each item in the channel, while the `.combine()` operator can take arguments like another channel or a `by` parameter on how to combine the channels.

There is a helpful github repo of common patterns using Nextflow channels that you can refer to. See [this link](https://nextflow-io.github.io/patterns/). 


**Exercise:** Read the [Process per CSV record](https://nextflow-io.github.io/patterns/process-per-csv-record/) and create a new file called `02_read_csv.nf`. Write a `workflow` that reads in the `samplesheet.csv` file and prints out each record using the `.view()` operator. The printout should be a tuple where the first item is the sample name and the second item is the file path (enclosed in `file()` so that Nextflow will check if it exists as part of the workflow).

??? example "Solution"

    ```nextflow
    #!/usr/bin/env nextflow

    workflow {
        // Create a channel that reads in the samplesheet
        samples = Channel.fromPath('samplesheet.csv')
            .splitCsv(header:true)
            .map { row -> tuple(row.sampleName, file(row.filePath)) }
        
        // Print out each record in the samplesheet
        samples.view()
    }
    ```

**Bonus:** Experiment with removing the `file()` wrapper and see what happens. Maybe add an extra line to the samplesheet with a non-existent file path.

### Writing your first Nextflow process

We will now use the `02_samplesheet.csv` file going forward. Now that we have a channel that reads in the samplesheet, let's write our first Nextflow process to count the number of lines in each input file. In the next two code blocks, I will show you two mostly equivalent ways to write the process call and explain the difference (and why I prefer to use the second, slightly more complicated, way). 

**First way:**

Save this code in a new file called `03_count_lines_simple.nf` and run it using `nextflow run 03_count_lines_simple.nf`.

```nextflow
#!/usr/bin/env nextflow

process COUNT_LINES {

    input:
    path input_file 
    
    output:
    path "${input_file.baseName}.lines"

    script:
    """
    wc -l ${input_file} | awk '{print \$1}' > ${input_file.baseName}.lines
    """
}

workflow {
    // Create a channel from a list of input files
    input_files = Channel.fromList([
        'data/sample1.txt',
        'data/sample2.txt'
    ])

    // Pass the input files to the COUNT_LINES process
    results = COUNT_LINES(input_files)

    results.view()
}
```

**Second way (preferred):**
Save this code in a new file called `04_count_lines.nf` and run it using `nextflow run 04_count_lines.nf`.

```nextflow
#!/usr/bin/env nextflow

process COUNT_LINES {
    input:
    tuple val(sample_name), path(input_file)

    output:
    tuple val(sample_name), path("${sample_name}.lines")

    script:
    """
    wc -l ${input_file} | awk '{print \$1}' > ${sample_name}.lines
    """
}

workflow {
    // Read the samplesheet.csv and create a channel of tuples (sample_name, file_path)
    samples = Channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .map { row -> tuple(row.sampleName, file(row.filePath)) }

    // Pass the tuples to the COUNT_LINES process
    results = COUNT_LINES(samples)

    // View the results
    results.view()
}
```

Compare the two `results.view()` outputs from the two scripts. Representative outputs are below:

The `results.view()` line should show something like this:

First script:

```
executor >  local (2)
[ba/163bd1] COUNT_LINES (1) [100%] 2 of 2 ✔
/../nextflow_workshop/develop/work/17/a7922d4378d328df6a74ec0558e292/sample1.lines
/../nextflow_workshop/develop/work/ba/163bd1279533ec8369cd890a43587b/sample2.lines
```

Second script:

```
[bb/779082] COUNT_LINES (1) [100%] 2 of 2 ✔
[sample1, /Users/leima/Github/nextflow_workshop/develop/work/bb/7790822842b5bba6c53c69b286332a/sample1.lines]
[sample2, /Users/leima/Github/nextflow_workshop/develop/work/f9/bc69d54beb8a9506bba3e9bac306f3/sample2.lines]
```

In the second script the channel output of `COUNT_LINES` is a tuple where the first item is the sample name and the second item is the path to the output file. This is because we defined both the input and output of the process as tuples, so that we can keep track of which sample corresponds to which output file. In the first script we only passed in the file paths, so the output is just the file paths. The benefit of using tuples is that we can keep track of metadata (such as sample names, conditions, etc.) without relying on file names alone. This means that downstream channel operations and processes can use this metadata without having to parse a file name to get at the information. 

Now let's do a more detailed breakdown of the process definition. 

A process typically consists of the following sections: 

* `input:` defines the inputs to the process. A process must contain at least one input section and each input needs to have a *qualifier* and a *name*. Common qualifiers are `path`, which causes a file to be staged properly, and `val`, which is some value that can be accessed in the script section. Input elements can be grouped into `tuple`s to pass multiple items together.
    * In our example, we have a `val` input called `sample_name` and a `path` input called `input_file`, grouped into a tuple. Notice how we don't need to specify how the `input_file` is named or created. This is handled by the channel that is passed to the process. In general, avoid referencing specific file paths or patterns in the process input section and in your script section use the input variable name defined in your input section. **This is different than how Snakemake works!**
* `output:` defines the outputs of the process. Similar to inputs, each output needs a *qualifier* and a *name*. Outputs can have dynamic names using the `${}` syntax, where the value inside the curly braces typically refers to an input variable.
    * In our `path` output, we use `${}` to access the value stored in `sample_name` from the input and pass it to the the output file name. 
    * The metadata `sample_name` is passed unchanged from input to output using the `val` qualifier. Combined with `tuple`, the metadata is preserved along with the output file. 
    * Although we have defined a unique output file name for each sample, Nextflow will still work well if we do not use dynamic output file names. This is because files produced by different tasks reside in their own work directory so they will not overwrite each other. However, if we want to publish the output files to a common directory, it is easier to do so if the output files have unique names.
* `script:` defines the the script executed by the process and is typically a bash script enclosed in triple quotes (`"""`). To access nextflow variables/pipeline parameters inside the script, use the `${}` syntax. If you need to access a literal dollar sign (`$`), such as in `awk` commands, you need to escape it using a single backslash (`\`), e.g. `\$1`. If you need to access system variables such as `$HOME`, you need to escape the dollar sign with two backslashes (`\\`), e.g. `\\$HOME`.
    * In our example, we use the `wc -l` command to count the number of lines in the input file and redirect the output to a new file named `${sample_name}.lines`. Another way to do this is to create the output file name beforehand using groovy syntax, e.g. `def output_file = "${sample_name}.lines"`, and then use `${output_file}` in the script section. This keeps the script section cleaner and easier to read.
    ```nextflow     
    script:
    def output_file = "${sample_name}.lines
    """
    wc -l ${input_file} | awk '{print \$1}' > ${output_file}
    """
    ```

Just because we have the process, doesn't mean that it will be run. We need to call the process like a function in the `workflow` definition section. In the `workflow` section we create the `samples` channel as before, but then instead of just viewing the channel, we pass it to the `COUNT_LINES` process. You can think of a `COUNT_LINES` as a function that expects an input channel consisting of a tuple of a val and a path, and returns an output channel consisting another tuple of a val and a path. Passing the correct channel to the process is how we "call" the process to be executed. The output of the process is another channel, which we assign to the variable `results`. Finally, we view the `results` channel to see the output of the process.

### Testing your workflow

#### Checking for syntax errors with `nextflow lint`

Now that we have a working process and workflow definition, we should test it to see if it works as expected. As you are writing your pipeline, it can be useful to use the `nextflow lint` command to check for syntax errors and formatting issues. We have a sample erroneous Nextflow script called `errors.nf` that you can use to test the linting command.

Run the following command in your terminal:

```bash
nextflow lint errors.nf
```

**Exercise:** Run `nextflow lint errors.nf` and identify the errors in the script. Once there are no more errors, try running `nextflow lint errors.nf -format` to automatically fix the formatting issues in the script. 

#### Previewing the workflow DAG

You can preview the workflow DAG directly in the VSCode editor if you have the Nextflow extension installed. Open the `04_count_lines.nf` file and click on the "Preview DAG" button in the top of the `workflow` section. This will open a window showing a DAG of the workflow. 

You can also generate a DAG without running the workflow by using the `-preview` and `-with-dag` flags when running the workflow. Run the following command in your terminal:

```bash
nextflow run 04_count_lines.nf -preview -with-dag workflow_dag.dot
```

!!! note "Using .dot files instead of .svg or .png"

    We're saving these as plaintext dot files because I don't want to take up time transferring the image files. Instead, I am going to use an online dot file viewer to visualize the DAGs. [Link](https://dreampuf.github.io/GraphvizOnline/){ target="_blank" }

You'll notice that this command generates a file that includes the channel names and operators, which can be useful for debugging, but it can also make the DAG cluttered and hard to read. To generate a cleaner DAG without channel names and operators, you can use the `-n` flag:
