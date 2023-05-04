# This script calculates P sites per codon


# Load libraries ----------------------------------------------------------
suppressPackageStartupMessages({
  library(tidyverse)
  library(rtracklayer)
})


# Input args --------------------------------------------------------------
args = commandArgs(trailingOnly=TRUE)

ref_bedf <- args[1]

bedfile_loc <- args[2]

out_dir <- args[3]

analysis_name <- args[4]

# Get lengths of reference ORFs -------------------------------------------
ref_bed <- data.table::fread(ref_bedf,
                             col.names = c("chrom", "start", "end", "ref_id", "frame", "strand")) %>%
  subset(!grepl("pATG|pST", .$frame)) 

ref_ORFs_codons <- ref_bed %>%
  group_by(ref_id) %>%
  summarize(n_codons = n()/3, length = n(), length_kb = n()/1000)


# Load bedIntersect files and calculate P sites per codon -----------------
intersect_files <- grep(
  pattern = "Medullo_Tissues_JP_intersect", 
  invert = T, 
  x = list.files(bedfile_loc, pattern = "intersect.bed", full.names = T), 
  value = T)

# psites_percodon <- data.frame(row.names = ref_ORFs_codons$ref_id)
ppm <- data.frame(row.names = ref_ORFs_codons$ref_id)
psites <- data.frame(row.names = ref_ORFs_codons$ref_id)

for(int_file in intersect_files){
  
  sample_name = gsub(pattern = "_intersect.bed", replacement = "", x = basename(int_file))
  
  intersect_bed <- data.table::fread(
    int_file,
    col.names = c("chrom", "start", "end", "transcript_id", "score", "strand", "chrom_ref", "start_ref", "end_ref", "ref_id", "ref_frame", "ref_strand")) 
  
  # Calculate fraction of p0, p1 and p2
  psites_test <- intersect_bed %>%
    subset(!grepl("pATG|pST", .$ref_frame)) %>% 
    group_by(ref_id) %>%
    mutate(tot = sum(score)) %>%
    group_by(ref_id, ref_frame, tot) %>%
    summarize(psites = sum(score)) %>%
    mutate(psitesfrac = psites/tot)
  
  # Select pX with highest fraction
  p_select <- psites_test %>%
    group_by(ref_id) %>%
    filter(psitesfrac == max(psitesfrac)) %>%
    transmute(frame_select = ref_frame)
  
  # For each ORF, only include P sites from selected pX
  intersect_bed <- left_join(intersect_bed, p_select) %>%
    group_by(ref_id) %>%
    filter(ref_frame == frame_select)
  
  # Calculate P sites and ppm
  psites_overlap <- intersect_bed %>%
    group_by(ref_id) %>%
    summarize(psites = sum(score)) %>% 
    full_join(ref_ORFs_codons) %>%
    mutate(psites = ifelse(is.na(psites), 0, psites)) %>%
    mutate(psites_perkb = psites/length_kb)
  
  scaling_factor <- sum(psites_overlap$psites_perkb)/1000000
  
  psites_overlap$ppm <- psites_overlap$psites_perkb/scaling_factor
  
  rownames(psites_overlap) <- psites_overlap$ref_id
  psites_overlap <- psites_overlap[rownames(psites), ]
  
  # psites_percodon[[sample_name]] <- psites_overlap$psites_percodon
  ppm[[sample_name]] <- psites_overlap$ppm
  psites[[sample_name]] <- psites_overlap$psites
}

# write.table(file = paste0(out_dir, "/", analysis_name, "_psites_percodon.txt"), x = psites_percodon, row.names = T, quote = F)
write.table(file = paste0(out_dir, "/", analysis_name, "_psites_permillion.txt"), x = ppm, row.names = T, quote = F)
write.table(file = paste0(out_dir, "/", analysis_name, "_psites.txt"), x = psites, row.names = T, quote = F)


