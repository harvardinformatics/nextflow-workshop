#!/usr/bin/env nextflow

workflow {
    // Create a channel that reads in the samplesheet
    samples = Channel.fromPath('samplesheet.csv')
        .splitCsv(header:true)
        .map { row -> tuple(row.sampleName, file(row.filePath)) }
    
    // Print out each record in the samplesheet
    samples.view()
}
