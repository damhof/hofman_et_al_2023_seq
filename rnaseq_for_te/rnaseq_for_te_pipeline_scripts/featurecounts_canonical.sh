#!/bin/bash

# This script uses featureCounts to count reads that map to canonical genes from Ensembl GRCh38.102

#SBATCH -t 10:00:00
#SBATCH --mem=50G
#SBATCH -c 8

module load subread/2.0.2  # subread contains featureCounts function

# Load reference files
# reference_genome="/hpc/pmc_vanheesch/shared_resources/GENOMES/Homo_sapiens.GRCh38/102/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
# gtf="/hpc/pmc_vanheesch/shared_resources/GENOMES/Homo_sapiens.GRCh38/102/annotation/Homo_sapiens.GRCh38.102.gtf" # Same as used for alignment and featurecounts in RNAseq regular
reference_genome=${reference_genome}
gtf=${reference_gtf}

# Load BAM files
bam_files=($(find "${outdir}/star/" -maxdepth 3 -name "*sortedByCoord.out.bam")) 

mkdir -p "${outdir}/featureCounts/"

featureCounts ${bam_files[@]} \
  -s 2 \
  -T 8 \
  -t "CDS" \
  -g "gene_id" \
  -J \
  -G ${reference_genome} \
  -a "${gtf}" \
  -o "${outdir}/featureCounts/Medullo_RNA_GRCh38.102.geneCountsCDS.txt"