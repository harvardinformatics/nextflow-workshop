workflow {
    // Create a channel that reads in the samplesheet & does some operations
    samples = Channel.fromPath('samplesheet.txt')
        .splitText()                                    // Emits: "sample1\n", "sample2\n"
        .map { sample -> sample.trim() }                // Emits: "sample1", "sample2"
        .map { sample -> file("data/${sample}.txt")}    // Emits: file objects for data/sample1.txt, data/sample2.txt

    
    // Print out each object in samples
    samples.view()
}
