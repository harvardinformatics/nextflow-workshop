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

process COMBINE_COUNTS {

    publishDir "results", mode: 'copy'

    input:
    tuple val(sample_id), path(lines_file), path(words_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.summary")
    script:
    """
    echo -n "lines\t" > ${sample_id}.summary
    cat ${lines_file} >> ${sample_id}.summary
    echo -n "words\t" >> ${sample_id}.summary
    cat ${words_file} >> ${sample_id}.summary
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

    joined_ch = COUNT_LINES.out.join(COUNT_WORDS.out)

    COMBINE_COUNTS(joined_ch)

}
