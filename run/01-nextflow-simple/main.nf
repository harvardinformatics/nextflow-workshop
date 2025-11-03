#!/usr/bin/env nextflow

params.samplesheet = "samplesheet.txt"
params.input_dir = "data"
params.outdir = "results"

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

/*
    * A process to count words in text files
    * for a list of samples provided in a sample sheet.
*/
process COUNT_WORDS {
    conda "conda-forge::gawk=5.1.0"
    
    input:
    tuple val(sample_id), path(input_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.words"), emit: words

    script:
    """
    wc -w ${input_file} | awk '{print \$1}' > ${sample_id}.words
    """
}

/*
    * A process to combine line and word counts
    * for each sample into a summary file.
*/
process COMBINE_COUNTS {
    conda "conda-forge::gawk=5.1.0"
    
    input:
    tuple val(sample_id), path(lines_file), path(words_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.summary"), emit: summary

    script:
    """
    echo -n "lines\t" > ${sample_id}.summary
    cat ${lines_file} >> ${sample_id}.summary
    echo -n "words\t" >> ${sample_id}.summary
    cat ${words_file} >> ${sample_id}.summary
    """
}

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

/*
    * The main workflow definition
*/
workflow {
    // Create input channel from sample sheet
    samples_ch = Channel
        .fromPath(params.samplesheet)
        .splitText()
        .map { sample -> sample.trim() }
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
