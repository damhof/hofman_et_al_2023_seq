#!/bin/bash

# 16-11-2022

# Make symlinks from central data folder to project data folder
ln -s /hpc/pmc_vanheesch/data/external/riboseq/20220720_DH_Medullo_JohnPrensner/Misc_files/*R1_001.fastq.gz /hpc/pmc_vanheesch/projects/Damon/Medulloblastoma_analyses_final/riboseq/data/raw/
ln -s /hpc/pmc_vanheesch/data/external/riboseq/20220720_DH_Medullo_JohnPrensner/Cell_lines/*R1_001.fastq.gz /hpc/pmc_vanheesch/projects/Damon/Medulloblastoma_analyses_final/riboseq/data/raw/
ln -s /hpc/pmc_vanheesch/data/external/riboseq/20220720_DH_Medullo_JohnPrensner/Tissues/*R1_001.fastq.gz /hpc/pmc_vanheesch/projects/Damon/Medulloblastoma_analyses_final/riboseq/data/raw/

# Remove corrupt symlinks
cd "/hpc/pmc_vanheesch/projects/Damon/Medulloblastoma_analyses_final/riboseq/data/raw/"

rm \
20211215_CHLA-01-MEDR_DMSO_JP9546_S11_R1_001.fastq.gz \
20211215_CHLA-01-MEDR_HHT_JP9545_S8_R1_001.fastq.gz \
20220510_CHLA259_HHT_2_0_Rnase_JP10031_S1_R1_001.fastq.gz \
20220510_D425_DMSO_JP10031_S17_R1_001.fastq.gz \
20220504_R262_HHT_EC9940_S15_R1_001.fastq.gz

# Merge files from the same samples and remove the original symlinks
cat 20220131_CHLA-259_siTOOLS_1x_JP9545_S1_R1_001.fastq.gz 20211215_CHLA-259_siTOOLS_1x_JP9545_S1_R1_001.fastq.gz 20220613_CHLA_259_siTOOLS_1x_JP10120_S4_R1_001.fastq.gz > ./merged_CHLA-259_siTOOLS_1x_R1_001.fastq.gz
rm 20220131_CHLA-259_siTOOLS_1x_JP9545_S1_R1_001.fastq.gz 20211215_CHLA-259_siTOOLS_1x_JP9545_S1_R1_001.fastq.gz 20220613_CHLA_259_siTOOLS_1x_JP10120_S4_R1_001.fastq.gz

cat 20220131_D384_DMSO_JP9546_S18_R1_001.fastq.gz 20220504_D384_DMSO_EC9940_S3_R1_001.fastq.gz 20211215_D384_DMSO_JP9546_S18_R1_001.fastq.gz > ./merged_D384_DMSO_R1_001.fastq.gz
rm 20220131_D384_DMSO_JP9546_S18_R1_001.fastq.gz 20220504_D384_DMSO_EC9940_S3_R1_001.fastq.gz 20211215_D384_DMSO_JP9546_S18_R1_001.fastq.gz

cat 20211215_D458_DMSO_2_0_Rnase_JP9546_S16_R1_001.fastq.gz 20220131_D458_DMSO_2_0_Rnase_JP9546_S16_R1_001.fastq.gz 20220131_D458_DMSO_6_0_Rnase_JP9546_S20_R1_001.fastq.gz 20220510_D458_DMSO_JP10031_S15_R1_001.fastq.gz 20211215_D458_DMSO_6_0_Rnase_JP9546_S20_R1_001.fastq.gz > ./merged_D458_DMSO_R1_001.fastq.gz
rm 20211215_D458_DMSO_2_0_Rnase_JP9546_S16_R1_001.fastq.gz 20220131_D458_DMSO_2_0_Rnase_JP9546_S16_R1_001.fastq.gz 20220131_D458_DMSO_6_0_Rnase_JP9546_S20_R1_001.fastq.gz 20220510_D458_DMSO_JP10031_S15_R1_001.fastq.gz 20211215_D458_DMSO_6_0_Rnase_JP9546_S20_R1_001.fastq.gz 

cat 20220510_S15_1824_JP10031_S11_R1_001.fastq.gz 20220613_S15_1824_JP10120_S1_R1_001.fastq.gz > ./merged_S15_1824_DMSO_R1_001.fastq.gz
rm 20220510_S15_1824_JP10031_S11_R1_001.fastq.gz 20220613_S15_1824_JP10120_S1_R1_001.fastq.gz

cat 20220131_CHLA-01-MEDR_HHT_JP9545_S8_R1_001.fastq.gz 20220613_CHLA_01_MEDR_HHT_JP10120_S8_R1_001.fastq.gz > ./merged_CHLA-01-MEDR_HHT_R1_001.fastq.gz
rm 20220131_CHLA-01-MEDR_HHT_JP9545_S8_R1_001.fastq.gz 20220613_CHLA_01_MEDR_HHT_JP10120_S8_R1_001.fastq.gz

cat 20220131_D384_HHT_JP9545_S9_R1_001.fastq.gz 20220504_D384_HHT_EC9940_S4_R1_001.fastq.gz 20211215_D384_HHT_JP9545_S9_R1_001.fastq.gz > ./merged_D384_HHT_R1_001.fastq.gz
rm 20220131_D384_HHT_JP9545_S9_R1_001.fastq.gz 20220504_D384_HHT_EC9940_S4_R1_001.fastq.gz 20211215_D384_HHT_JP9545_S9_R1_001.fastq.gz
