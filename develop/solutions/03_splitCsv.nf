#!/usr/bin/env nextflow

workflow {
    // Create a channel that reads in the samplesheet
    samples = Channel.fromPath('samplesheet.csv')
        .splitCsv(header:true)
        .map { row -> file(row.filePath) }
    
    // Print out each record in the samplesheet
    samples.view()
}
