#!/usr/bin/env nextflow

process COUNT_LINES {
    input:
    tuple val(sample_name), path(input_file)

    output:
    tuple val(sample_name), path("${input_file.baseName}.lines")

    script:
    """
    wc -l ${input_file} | awk '{print \$1}' > ${input_file.baseName}.lines
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
