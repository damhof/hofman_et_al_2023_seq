#!/bin/bash

# RNAseq_regular.sh
#
# A pipeline script for processing RNA-seq data using SLURM workload manager and lmod module system. 
# The script identifies the fastq files for each sample and initiates a SLURM array to execute the pipeline steps for each sample in parallel. 
# The steps include quality control, trimming, strandedness check, alignment, and quantification.
# This pipeline performs 'regular' analysis, using full read lengths etc for the analyses, in contrast to the pipeline used for TE calculation.
# See the config_file.sh for module dependencies, version numbers, and reference files used.
#
# List of output files
# - for each sample, trimmed and filtered fastq files (<sample_id>_trimmed_R1_001.fastq.gz and <sample_id>_trimmed_R2_001.fastq.gz)
# - trim_stats.txt: contains number and percentage of total reads after trimming
# - .txt files for each sample indicating read strandedness, as well as a summary .txt file 
# - BAM files containing reads aligned with STAR, as well as BAM index files generated with samtools
# - samtools stats files containing read alignment stats (e.g. unmapped, multi-mapped, etc.)
# - Read counts table produced by trimgalore
# 
# Authors:
# Damon Hofman (d.a.hofman-3@prinsesmaximacentrum.nl)
# Jip van Dinter (j.t.vandinter-3@prinsesmaximacentrum.nl)
#
# Date: 12-04-2023

set -uo pipefail

function usage() {
    cat <<EOF
SYNOPSIS
  run_rnaseq_regular_pipeline.sh [-c <config file>] [-h]
DESCRIPTION
  Run the RNAseq processing pipeline consisting of the following steps:
  1. Trim reads with trimgalore (wrapper for cutadapt and fastqc)
  2. Check strandedness of reads with 'howarewestrandedhere'
  3. Map reads with STAR
  4. Create BAM index file and generate read stats with samtools
  5. Quantify gene-level CDS read counts with featureCounts
OPTIONS
  -c, --config <file>    Configuration file to use
  -h, --help             Display this help message
AUTHOR
  Jip van Dinter, MSc
  Damon Hofman, MSc
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--config)
    CONFIG="$2"
    shift
    shift
    ;;
    -h|--help)
    usage
    exit
    ;;
    "")
    echo "Error: no option provided"
    usage
    exit 1
    ;;
    *)
    echo "Unknown option: $key"
    usage
    exit 1
    ;;
esac
done

# Check that configuration file is provided
if [[ -z ${CONFIG+x} ]]; then 
    echo "Error: no configuration file provided"
    usage
    exit 1
fi

# Load config file
echo "Loading configuration from: $CONFIG"
source $CONFIG || { echo "Failed to load configuration"; exit 1; }

# Load general functions
echo "Loading general functions from: ${scriptdir}/general_functions.sh"
source ${scriptdir}/general_functions.sh || { echo "Failed to load general functions"; exit 1; }

# Create a unique prefix for the names for this run of the pipeline
# This makes sure that runs can be identified
run=$(uuidgen | tr '-' ' ' | awk '{print $1}')

# Find samples
echo "$(date '+%Y-%m-%d %H:%M:%S') Finding samples..."
get_samples $project_data_folder $data_folder $paired_end || { echo "Failed to get samples"; exit 1; }

printf "%s\n" "${r1_files[@]}" > r1_files.txt
printf "%s\n" "${r2_files[@]}" > r2_files.txt
printf "%s\n" "${sample_ids[@]}" > sample_ids.txt
printf "%s\n" "${specific_samples[@]}" > samples.txt

# Create output directories
mkdir -p log/${run}/{trimgalore,star,samtools,howarewestrandedhere} 
mkdir -p ${outdir}

##############################################################################

# Step 1: quality control
trim_jobid=()
trim_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=4 \
  --time=24:00:00 \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.trimgalore \
  --output=log/${run}/trimgalore/%A_%a.out \
  --export=ALL,r1_files=${r1_files[@]},r2_files=${r2_files[@]},sample_ids=${sample_ids[@]} \
  ${scriptdir}/trimgalore.sh \
))
info "Trimgalore jobid: ${trim_jobid[@]}"


# Step 2: Check strandedness
strand_jobid=()
strand_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=2 \
  --time=24:00:00 \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.howarewestrandedhere \
  --output=log/${run}/howarewestrandedhere/%A_%a.out \
  --export=ALL,r1_files=${r1_files[@]},r2_files=${r2_files[@]},sample_ids=${sample_ids[@]} \
  ${scriptdir}/check_strand.sh \
))
info "Howarewestrandedhere jobid: ${strand_jobid[@]}"


# Step 3: Align with STAR
star_jobid=()
star_jobid+=($(sbatch --parsable \
  --mem=200G \
  --cpus-per-task=16 \
  --time=24:00:00 \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.star_align \
  --output=log/${run}/star/%A_%a.out \
  --dependency=aftercorr:${trim_jobid} \
  --export=ALL \
  ${scriptdir}/star_align.sh
))
info "STAR alignment jobid: ${star_jobid[@]}"


# Step 4: Create bam index file and generate mapping statistics with samtools
samtools_jobid=()
samtools_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=16 \
  --gres=tmpspace:100G \
  --time=24:00:00 \
  --job-name=${run}.samtools \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --output=log/${run}/samtools/%A_%a.out \
  --dependency=aftercorr:${star_jobid} \
  --export=ALL \
  ${scriptdir}/samtools.sh \
))
info "Samtools jobid: ${samtools_jobid[@]}"


# Step 5: Quantify gene-level CDS reads with featureCounts
featurecounts_jobid=()
featurecounts_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=8 \
  --time=24:00:00 \
  --job-name=${run}.featurecounts \
  --output=log/${run}/%A_featurecounts.out \
  --dependency=afterok:${samtools_jobid} \
  --export=ALL \
  ${scriptdir}/featurecounts.sh \
))
info "FeatureCounts jobid: ${featurecounts_jobid[@]}"
