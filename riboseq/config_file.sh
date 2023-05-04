#!/bin/bash

# Run parameters
export wd=`pwd`
export project_data_folder="${wd}/data/"
export outdir="${wd}/data/processed/"
export simul_array_runs=30
export species="Homo_sapiens"
export genome_version="GRCh38"
export annot="102"
export pool_id="Medullo_merged"

# Set paths
export resource_dir="/hpc/pmc_vanheesch/shared_resources/"
export scriptdir="${wd}/riboseq_pipeline_scripts/"
export data_folder="/hpc/pmc_vanheesch/data"  # Data folder containing all of our sequencing data

# Set reference files
export reference_annotation="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/annotation/Homo_sapiens.GRCh38.102.gtf_Rannot"
export reference_gtf="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/annotation/Homo_sapiens.GRCh38.102.gtf"
export star_index_basedir="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/STAR/2.7.8a"
export reference_gtf="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/annotation/Homo_sapiens.GRCh38.102.gtf"
export reference_annotation_package="${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/annotation/BSgenome.Homo.sapiens.GRCh38.102"
export reference_genome="/${resource_dir}/GENOMES/Homo_sapiens.GRCh38/102/Homo_sapiens.GRCh38.dna.primary_assembly.fa"

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
export pandoc_dir="/hpc/local/CentOS7/pmc_vanheesch/software/pandoc/bin"
export r_version=4.1.2