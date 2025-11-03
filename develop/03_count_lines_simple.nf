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
    input_files = Channel.fromPath([
        'data/sample1.txt',
        'data/sample2.txt'
    ])

    // Pass the input files to the COUNT_LINES process
    results = COUNT_LINES(input_files)

    results.view()
}
