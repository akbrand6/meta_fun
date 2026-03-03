#!/usr/bin/env nextflow

workflow {
    read_csv = Channel.fromPath("$params.index")
    | splitCsv( header: true )
    whokaryote_out = whokaryote(read_csv)
    concoct_output = concoct(whokaryote_out[0], whokaryote_out[1], whokaryote_out[2], whokaryote_out[3])
    busco_out = busco(concoct_output[0], concoct_output[1])
    eukdetect_taxa(busco_out[0], busco_out[1])
    kaiju_taxa(busco_out[0], busco_out[1])
}


process whokaryote {
    conda '/zfs/omics/projects/metatools/TOOLS/miniconda3/envs/whokaryote_v1.1.2/'
    tag "Running whokaryote on $sample"
    publishDir "${params.outdir}", mode: 'rellink'

    input:
    tuple val(sample), path(imp3_output)

    output:
    val sample
    path "${sample}/whokaryote/eukaryotes.fasta"   
    path "${sample}/whokaryote/${sample}.reads.eukaryote.bam"
    path "${sample}/whokaryote/${sample}.reads.eukaryote.bam.bai"
    path "${sample}/whokaryote/*.*"

    script:
    
    """
    mkdir -p ${sample}/whokaryote
    whokaryote.py --contigs ${imp3_output}/Assembly/mg.assembly.merged.fa --outdir ${sample}/whokaryote --f

    samtools view -h ${imp3_output}/Assembly/mg.reads.sorted.bam | grep -E "^@|\$(paste -sd'|' ${sample}/whokaryote/eukaryote_contig_headers.txt)"   | samtools view -b -o ${sample}/whokaryote/${sample}.reads.eukaryote.bam -
    samtools index ${sample}/whokaryote/${sample}.reads.eukaryote.bam
    mkdir -p "${params.outdir}/mapped"
    cp ${sample}/whokaryote/${sample}.reads.eukaryote.bam* "${params.outdir}/mapped/"
    """
}

process concoct {
    conda '/zfs/omics/personal/15938654/miniconda3/envs/concoct_env'
    tag "Running CONCOCT on $sample"
    publishDir "${params.outdir}", mode: 'rellink'

    input: 
    val sample
    path eukaryote_fasta
    path sample_bam
    path sample_bam_bai


    output:
    val sample
    path "${sample}/concoct/fasta_bins/"
    path "${sample}/concoct/*"

    script:

    """
    mkdir -p ${sample}/concoct/binning
    cut_up_fasta.py ${eukaryote_fasta} -c 10000 -o 0 --merge_last -b ${sample}/concoct/binning/contigs_10k.bed > ${sample}/concoct/binning/contigs_10k.fa
    concoct_coverage_table.py ${sample}/concoct/binning/contigs_10k.bed ${sample_bam} > ${sample}/concoct/binning/coverage_table.tsv

    mkdir ${sample}/concoct/${sample}_concoct_output
    concoct -t 8 --composition_file ${sample}/concoct/binning/contigs_10k.fa --coverage_file ${sample}/concoct/binning/coverage_table.tsv -b ${sample}/concoct/${sample}_concoct_output

    merge_cutup_clustering.py ${sample}/concoct/${sample}_concoct_output/clustering_gt1000.csv > ${sample}/concoct/${sample}_concoct_output/clustering_merged.csv
    mkdir -p ${sample}/concoct/fasta_bins
    extract_fasta_bins.py ${eukaryote_fasta} ${sample}/concoct/${sample}_concoct_output/clustering_merged.csv --output_path ${sample}/concoct/fasta_bins

    """
}


process busco {
    conda '/zfs/omics/personal/15938654/miniconda3/envs/busco_env'
    tag "running Busco on $sample"
    publishDir "${params.outdir}/${sample}/busco", mode: 'rellink'

    input:
    val sample
    path fasta_bins


    output:
    val sample
    path "bins_that_pass_busco_min.txt"
    path "*"


    script:
    
    """
    busco -m genome -f -i ${fasta_bins}/ -l /zfs/omics/projects/metatools/DB/busco/eukaryota_odb12 -o ${sample} --offline
    python ${params.batch_summary_script} ${sample}/batch_summary.txt bins_that_pass_busco_min.txt
    """
}

process eukdetect_taxa{
    conda '/zfs/omics/personal/15938654/miniconda3/envs/bowtie2_env'
    tag "Running bowtie2 on $sample"
    publishDir "${params.outdir}/${sample}/taxa/eukdetect", mode: 'rellink'

    input:
    val sample
    path bins_out_of_busco

    output:
    val sample
    path bins_out_of_busco
    path "*"

    script:
    """
    while read bin
        do ${params.sam_processing_script} ${params.outdir}/${sample}/concoct/fasta_bins/\$bin
    done < ${bins_out_of_busco}

    """
}

process kaiju_taxa{
    conda '/zfs/omics/projects/metatools/TOOLS/miniconda3/envs/kaiju_env'
    tag "Running kaiju on $sample"
    publishDir "${params.outdir}/${sample}/taxa/kaiju", mode: 'rellink'

    input:
    val sample
    path bins_out_of_busco

    output:
    val sample
    path bins_out_of_busco
    path "*"

    script:
    """
    nodesdp="/zfs/omics/projects/metatools/DB/kaiju_nr_euk/download/nodes.dmp"
    namesdp="/zfs/omics/projects/metatools/DB/kaiju_nr_euk/download/names.dmp"
    fmi="/zfs/omics/projects/metatools/DB/kaiju_nr_euk/download/kaiju_db_nr_euk.fmi"
    while read bin
        do kaiju -t \$nodesdp -f \$fmi -i ${params.outdir}/${sample}/concoct/fasta_bins/\$bin -o \${bin}.kaiju_out
        kaiju2table -t \$nodesdp -n \$namesdp -r species -o \${bin}_kaiju_summary.tsv \${bin}.kaiju_out
    done < ${bins_out_of_busco}

    """
}