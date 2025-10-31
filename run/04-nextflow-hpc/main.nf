#!/usr/bin/env nextflow

// Default parameters
params.samplesheet = "samplesheet.txt"
params.input_dir = "data"
params.outdir = "results"

/*
 * A process to count lines in text files
 * for a list of samples provided in a sample sheet.
 */
process COUNT_LINES {
    tag "$sample_id"

    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(sample_id), path(input_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.lines"), emit: lines
    
    when:
    params.run_lines

    script:
    """
    echo "Processing $sample_id for line counting..."
    wc -l ${input_file} | awk '{print \$1}' > ${sample_id}.lines
    echo "Lines counted: \$(cat ${sample_id}.lines)"
    """
}

/*
 * A process to count words in text files
 * for a list of samples provided in a sample sheet.
 */
process COUNT_WORDS {
    tag "$sample_id"
    
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(sample_id), path(input_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.words"), emit: words
    
    when:
    params.run_words

    script:
    """
    echo "Processing $sample_id for word counting..."
    wc -w ${input_file} | awk '{print \$1}' > ${sample_id}.words
    echo "Words counted: \$(cat ${sample_id}.words)"
    """
}

/*
 * A process to combine line and word counts
 * for each sample into a summary file.
 */
process COMBINE_COUNTS {
    tag "$sample_id"
    
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(sample_id), path(lines_file), path(words_file)
    
    output:
    tuple val(sample_id), path("${sample_id}.summary"), emit: summary

    script:
    """
    echo "Combining counts for $sample_id..."
    echo -n "lines\t" > ${sample_id}.summary
    cat ${lines_file} >> ${sample_id}.summary
    echo -n "words\t" >> ${sample_id}.summary
    cat ${words_file} >> ${sample_id}.summary
    echo "Summary created for $sample_id"
    """
}

/*
 * A process to aggregate all summary files
 * into a single TSV file.
 */
process AGGREGATE {
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    path summary_files
    
    output:
    path "aggregate-summary.tsv"
    
    when:
    params.run_aggregate

    script:
    """
    echo "Aggregating all summaries..."
    echo -e "sample\tlines\twords" > aggregate-summary.tsv
    for summary_file in ${summary_files}; do
        SAMPLE_NAME=\$(basename "\$summary_file" .summary)
        LINES=\$(grep -e "^lines\t" "\$summary_file" | cut -f2)
        WORDS=\$(grep -e "^words\t" "\$summary_file" | cut -f2)
        echo -e "\$SAMPLE_NAME\t\$LINES\t\$WORDS" >> aggregate-summary.tsv
    done
    echo "Aggregation complete!"
    """
}

process COWPY {
    publishDir "${params.outdir}", mode: 'copy'
    container 'community.wave.seqera.io/library/pip_cowpy:8b70095d527cd773'
    conda 'conda-forge::cowpy==1.1.5'
    
    input:
    val samples_processed

    output:
    path "cowpy-output.txt"

    script:
    MESSAGE="Workflow completed! Samples processed: ${samples_processed.join(', ')}"
    """
    echo $MESSAGE | cowpy > cowpy-output.txt
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
        .map { it.trim() }
        .filter { it != "" }  // Remove empty lines
        .map { sample -> tuple(sample, file("${params.input_dir}/${sample}.txt")) }
    
    // Show what samples we're processing
    samples_ch.view { sample_id, file -> "Processing sample: $sample_id from file: $file" }
    
    // Collect sample names for cowpy
    processed_samples = samples_ch.map { sample_id, file -> sample_id }.collect()

    // Run processes conditionally based on parameters
    if (params.run_lines) {
        COUNT_LINES(samples_ch)
    }
    
    if (params.run_words) {
        COUNT_WORDS(samples_ch)
    }
    
    // Only combine if both processes ran
    if (params.run_lines && params.run_words) {
        // Join the outputs and combine counts
        combined_ch = COUNT_LINES.out.lines.join(COUNT_WORDS.out.words)
        COMBINE_COUNTS(combined_ch)
        
        // Collect and aggregate all results if requested
        if (params.run_aggregate) {
            AGGREGATE(COMBINE_COUNTS.out.summary.collect { it[1] })
        }
    }
    
    // Run cowpy with the list of processed samples
    COWPY(processed_samples)
}
