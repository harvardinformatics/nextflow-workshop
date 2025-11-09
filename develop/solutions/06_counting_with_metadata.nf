#!/usr/bin/env nextflow

process COUNT_LINES {

    publishDir 'results', mode: 'copy'

    input: 
    tuple val(sample_name), path(input_file)

    output: 
    tuple val(sample_name), path("${sample_name}.lines")

    script:
    """
    wc -l ${input_file} | awk '{print \$1}' > ${sample_name}.lines
    """
}

process COUNT_WORDS {
    
    publishDir 'results', mode: 'copy'

    input: 
    tuple val(sample_name), path(input_file)

    output: 
    tuple val(sample_name), path("${sample_name}.words")
    script:
    """
    wc -w ${input_file} | awk '{print \$1}' > ${sample_name}.words
    """
}

workflow {
    // Create a channel that reads in the samplesheet
    samples = Channel.fromPath('samplesheet.csv')
        .splitCsv(header:true)
        .map { row -> tuple(row.sampleName , file(row.filePath)) }
    
    // Print out each record in the samplesheet
    samples.view()

    COUNT_LINES(samples)

    COUNT_WORDS(samples)

    COUNT_LINES.out.view()
    COUNT_WORDS.out.view()
}
