process COWPY {

    publishDir 'results', mode: 'copy'

    conda 'envs/cowpy.yaml'

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("${meta.animal}_mod-${meta.mod}.txt")

    script:
    """
    cat ${input_file} | cowpy -c ${meta.animal} > ${meta.animal}_mod-${meta.mod}.txt
    """
}

process CONVERT_TO_UPPERCASE {

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("modded_file.txt")

    script:
    """
    cat ${input_file} | tr '[a-z]' '[A-Z]' > modded_file.txt
    """
}

process CONVERT_TO_LOWERCASE {

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("modded_file.txt")

    script:
    """
    cat ${input_file} | tr '[A-Z]' '[a-z]' > modded_file.txt
    """
}

process DUPLICATE {
    
    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("modded_file.txt")

    script:
    """
    cat ${input_file} ${input_file} > modded_file.txt
    """
}

workflow {
    ch_samples = Channel.fromPath('samplesheet.csv')
        .splitCsv(header: true)
        .map { row -> 
            tuple(
                [
                    sampleName: row.sampleName,
                    animal: row.animal,
                    mod: row.mod
                ], 
                file(row.filePath)
            )
        }
    
    ch_samples.view()
    //COWPY(ch_samples)

    //ch_samples.filter { meta, file -> meta.mod == 'duplicate' }.view{meta, file -> "Processing sample: $meta.animal from $file.name with $meta.mod" }
    DUPLICATE(ch_samples.filter { meta, file -> meta.mod == 'duplicate' })
    
    //ch_samples.filter { meta, file -> meta.mod == 'uppercase' }.view{meta, file -> "Processing sample: $meta.animal from $file.name with $meta.mod" }
    CONVERT_TO_UPPERCASE(ch_samples.filter { meta, file -> meta.mod == 'uppercase' })
    
    //ch_samples.filter { meta, file -> meta.mod == 'lowercase' }.view{meta, file -> "Processing sample: $meta.animal from $file.name with $meta.mod" }
    CONVERT_TO_LOWERCASE(ch_samples.filter { meta, file -> meta.mod == 'lowercase' })
    
    ch_combined = DUPLICATE.out.mix(CONVERT_TO_UPPERCASE.out, CONVERT_TO_LOWERCASE.out)
    
    COWPY(ch_combined)
    
}
