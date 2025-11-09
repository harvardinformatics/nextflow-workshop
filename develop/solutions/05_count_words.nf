#!/usr/bin/env nextflow

process COUNT_LINES {

    publishDir 'results', mode: 'copy'

    input: 
    path input_file

    output: 
    path "${input_file.baseName}.lines"

    script:
    """
    wc -l ${input_file} | awk '{print \$1}' > ${input_file.baseName}.lines
    """
}

process COUNT_WORDS {
    
    publishDir 'results', mode: 'copy'

    input: 
    path input_file

    output: 
    path "${input_file.baseName}.words"

    script:
    """
    wc -w ${input_file} | awk '{print \$1}' > ${input_file.baseName}.words
    """
}

workflow {
    // Create a channel that reads in the samplesheet
    samples = Channel.fromPath('samplesheet.csv')
        .splitCsv(header:true)
        .map { row -> file(row.filePath) }
    
    // Print out each record in the samplesheet
    samples.view()

    COUNT_LINES(samples)

    COUNT_WORDS(samples)
}
