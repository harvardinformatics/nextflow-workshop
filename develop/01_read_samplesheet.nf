workflow {
    // Create a channel that reads in the samplesheet
    samples = Channel.fromPath('samplesheet.txt')
        .splitText()
        .map { sample -> sample.trim() }
        .map { sample -> tuple(sample, file("data/${sample}.txt"))}
    
    // Print out each line in the samplesheet
    samples.view()
}
