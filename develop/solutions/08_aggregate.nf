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

process AGGREGATE {

    publishDir "results", mode: 'copy'

    input:
    path summary_files

    output:
    path "aggregate-summary.tsv"

    script:
    """    
    echo -e "sample\tlines\twords" > aggregate-summary.tsv
    
    for sample in ${summary_files}; do
        SAMPLE_NAME=\$(basename "\$sample" .summary)
        LINES=\$(cat "\$sample" | grep -e "^lines\t" | cut -f2)
        WORDS=\$(cat "\$sample" | grep -e "^words\t" | cut -f2)
        echo -e "\$SAMPLE_NAME\t\$LINES\t\$WORDS" >> aggregate-summary.tsv
    done
    """
}

workflow {
    // Create a channel that reads in the samplesheet
    samples = Channel.fromPath('samplesheet.csv')
        .splitCsv(header:true)
        .map { row -> tuple(row.sampleName , file(row.filePath)) }

    COUNT_LINES(samples)

    COUNT_WORDS(samples)

    joined_ch = COUNT_LINES.out.join(COUNT_WORDS.out)

    COMBINE_COUNTS(joined_ch)

    AGGREGATE(COMBINE_COUNTS.out.collect{sample_name, summary_file -> summary_file})

}
