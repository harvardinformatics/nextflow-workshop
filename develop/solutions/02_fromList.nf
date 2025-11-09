#!/usr/bin/env nextflow

workflow {
    // Create a channel from a list of strings
    samples = Channel.fromList([
        'sample1',
        'sample2',
        'sample3'
    ]).map { sample -> file("data/${sample}.txt")}
    
    // Print out each line in the samplesheet
    samples.view()
}
