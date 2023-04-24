#!/bin/bash

# This script generates a Salmon index based on the merged custom GTF annotation file containing non-canonical and MANE ORF definitions

# Load modules
module load gffread/0.12.6
module load salmon
module load R/4.1.2

mkdir -p "${outdir}/salmon_index"

# Set locations
merged_gtf_location="${wd}/data/MANE_GENCODEp1_ORFEOME3_CDS.merged_notxversion_new.gtf"
merged_cds_gtf_out="${outdir}/salmon_index/merged_cds.gtf"
fixed_cds_gtf_out="${outdir}/salmon_index/tx_cds.gtf"
fixed_cds_fasta_out="${outdir}/salmon_index/tx_cds.fa"
gentrome_out="${outdir}/salmon_index/gentrome.fa"
decoy_out="${outdir}/salmon_index/decoys.txt"

# Extract CDS regions from merged custom GTF file
Rscript ${scriptdir}/extract_cds_gtf.R ${merged_gtf_location} ${merged_cds_gtf_out}

# Fix GTF file to give all CDS regions an exon and parent transcript
gffread \
  -g ${reference_genome} \
  -F \
  --keep-exon-attrs \
  --force-exons \
  -T \
  -o "${fixed_cds_gtf_out}" \
  ${merged_cds_gtf_output}

# Extract CDS sequences into fasta file
gffread \
  -g "${reference_genome}" \
  -x "${fixed_cds_fasta_out}" \
  "${fixed_cds_gtf_out}"

# Make gentrome
cat "${fixed_cds_fasta_out}" "${reference_genome}" > ${gentrome_out}

# Make salmon decoy
grep "^>" "${reference_genome}" | cut -d " " -f 1 > ${decoy_out}
sed -i.bak -e 's/>//g' ${decoy_out}

# Create salmon index
salmon index \
  --transcripts ${gentrome_out} \
  --decoys ${decoy_out} \
  --index "${outdir}/salmon_index/MANE_GENCODE_ORFEOME_CDS" \
  --kmerLen 13 \
  --keepDuplicates \
  --threads 8