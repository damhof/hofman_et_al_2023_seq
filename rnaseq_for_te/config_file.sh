#!/bin/bash

# Run parameters
export wd=`pwd`
export project_data_folder="${wd}/data/"
export outdir="${wd}/data/processed/"
export simul_array_runs=30
export species="Homo_sapiens"
export genome_version="GRCh38"
export annot="102"
# export custom_gtf="/hpc/pmc_vanheesch/projects/Damon/Medulloblastoma_ORFs/20221007_Medullo_RNAseqForTE/data/MANE.GRCh38.v1.0.ensembl_genomic.nochr_noversions.gtf"
# export custom_annotation="none"

# Set paths
export resource_dir="/hpc/pmc_vanheesch/shared_resources/"
export scriptdir="${wd}/scripts/"
export data_folder="/hpc/pmc_vanheesch/data"  # Data folder containing all of our sequencing data

# Set reference files
export star_index_basedir="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/STAR/2.7.8a"
export reference_gtf="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/annotation/Homo_sapiens.GRCh38.102.gtf"
export refseq_gtf="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/annotation/Homo_sapiens_GRCh38.p13"
export reference_genome="/${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
export masked_fasta="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa"
export twobit="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/Homo_sapiens.GRCh38.dna.primary_assembly.2bit"
export kallisto_index="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/kallisto/0.44/kallisto_index"
export bowtie2_index="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/bowtie2/2.4.2/heesch_strict_riboseq_contaminants"  ## Make sure to use the same index as for RIBO-seq
#heesch_strict_riboseq_contaminants
#berlin_lean_riboseq_contaminants

# Module versions
export cutadapt_version=3.4
export fastqc_version=0.11.9
export trimgalore_version=0.6.6
export bowtie2_version=2.4.2
export star_version=2.7.8a
export samtools_version=1.12
export subread_version=2.0.2
export multiqc_version=1.11
export pandoc_dir="/hpc/local/CentOS7/pmc_vanheesch/software/pandoc/bin"
