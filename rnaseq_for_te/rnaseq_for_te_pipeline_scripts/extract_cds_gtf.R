# Load libraries
library(tidyverse)
library(rtracklayer)
library(GenomicRanges)
library(Rsubread)

args <- commandArgs(trailingonly=TRUE)

merged_gtf_location = args[1]
merged_cds_gtf_output = args[2]

# Load merged GTF (MANE GTF merged with GENCODEp1_ORFEOME GTF (got from Jorge), removed tx versions and made seqnames comparable, then sorted by position)
merged_gtf <- import(merged_gtf_location)

# Get indices of CDS regions that are non-canonical and have no orf id
canonical_orf_ind <- which(merged_gtf$type == "CDS" & merged_gtf$source != "phaseI" & is.na(merged_gtf$orf_id))

# Set orf_id for these CDS regions as the 'transcriptID_CDS'
merged_gtf[canonical_orf_ind,]$orf_id <- paste0(merged_gtf[canonical_orf_ind,]$transcript_id, "_CDS")
merged_gtf_df <- data.frame(merged_gtf)

# Extract only CDS regions and set transcript ID to match ORF ID
cds_df <- subset(merged_gtf_orfids_df, type == "CDS")
cds_df$transcript_id <- cds_df$orf_id

# Export to be loaded by Salmon
export(cds_df, merged_cds_gtf_output)

# Next, generate Salmon index using `/hpc/pmc_vanheesch/projects/Damon/Medulloblastoma_analyses/01_processed_data/05_salmon_quant_ribo_rna/salmon_index.sh`





