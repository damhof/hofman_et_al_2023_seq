#!/bin/bash

# 01_run_riboseq_pipeline.sh
#
# Authors:
# Damon Hofman (d.a.hofman-3@prinsesmaximacentrum.nl)
# Jip van Dinter (j.t.vandinter-3@prinsesmaximacentrum.nl)
#
# Date: 24-04-2023

set -uo pipefail

function usage() {
    cat <<EOF
SYNOPSIS
  01_run_riboseq_pipeline.sh [-c <config file>] [-h]
DESCRIPTION
  1. Run TRIMGALORE on ribo-seq reads
  2. Remove contaminants from FASTQ with BOWTIE
  3. Align reads with STAR
  4. Run featureCounts to quantify canonical CDS read counts
  5. Perform QC and extract P sites from ribo-seq reads with RiboseQC
  6. Quantify P-sites in canonical CDSs
  7. Quantify P-sites in non-canonical ORFs
  8. Merge BAMs
  9. Run RiboseQC on merged BAMs
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

# Create a unique prefix for the names for this run of the pipeline. 
# This makes sure that runs can be identified
run=$(uuidgen | tr '-' ' ' | awk '{print $1}')

# Get correct annotation files
check_annotation ${reference_annotation} ${reference_gtf} ${reference_annotation_package}

# Find samples
echo "$(date '+%Y-%m-%d %H:%M:%S') Finding samples..."
get_samples $project_data_folder $data_folder || { echo "Failed to get samples"; exit 1; }

printf "%s\n" "${r1_files[@]}" > r1_files.txt
printf "%s\n" "${sample_ids[@]}" > sample_ids.txt
printf "%s\n" "${samples[@]}" > samples.txt

# Create output directories
mkdir -p log
mkdir -p ${outdir}


# Step 1: read timming and filtering
trim_jobid=()
trim_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=4 \
  --time=24:00:00 \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.trimgalore \
  --output=log/${run}.trimgalore.%A_%a \
  --export=ALL,r1_files=${r1_files[@]},sample_ids=${sample_ids[@]} \
  ${scriptdir}/trimgalore.sh \
))
info "trimgalore jobid: ${trim_jobid}"


# Step 2: remove contaminant reads with bowtie2
contaminant_jobid=()
contaminant_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=6 \
  --time=24:00:00 \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.contaminant \
  --output=log/${run}.contaminant.%A_%a \
  --dependency=aftercorr:${trim_jobid} \
  --export=ALL,r1_files=${r1_files[@]},sample_ids=${sample_ids[@]} \
  ${scriptdir}/remove_contaminants.sh 
))
info "contaminant jobid: ${contaminant_jobid}"


# Step 3: Align trimmed and filtered reads with STAR
star_jobid=()
star_jobid+=($(sbatch --parsable \
  --mem=50G \
  --cpus-per-task=16 \
  --time=24:00:00 \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.star_align \
  --output=log/${run}.star_align.%A_%a \
  --dependency=aftercorr:${contaminant_jobid} \
  --export=ALL \
  ${scriptdir}/star_align.sh
))
info "STAR alignment jobid: ${star_jobid[@]}"

# Step 4: Run featureCounts to quantify canonical CDS read counts
featurecounts_jobid=()
featurecounts_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=8 \
  --time=24:00:00 \
  --job-name=${run}.featurecounts \
  --output=log/${run}/%A_featurecounts.out \
  --dependency=afterok:${star_jobid} \
  --export=ALL \
  ${scriptdir}/featurecounts_canonical.sh \
))
info "FeatureCounts jobid: ${featurecounts_jobid[@]}"

# Step 5: Perform QC and extract P sites from ribo-seq reads with RiboseQC
riboseqc_jobid=()
riboseqc_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=2 \
  --time=24:00:00 \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.riboseqc \
  --output=log/${run}.riboseqc.%A_%a \
  --dependency=aftercorr:${star_jobid} \
  --export=ALL \
  ${scriptdir}/riboseqc.sh
))
info "RiboseQC jobid: ${riboseqc_jobid}"


# Step 6: Quantify canonical ORF P sites
canonical_psites_jobid=()
canonical_psites_jobid+=($(sbatch --parsable \
 --mem=20G \
 --cpus-per-task=4 \
 --time=24:00:00 \
 --job-name=${run}.canonical_psites \
 --output=log/${run}.canonical_psites \
 --dependency=afterok:${riboseqc_jobid} \
 ${scriptdir}/detect_ORF_overlap_psites_MANE.sh
))


# Step 7: Quantify GENCODE phase I and ORFEOME ORF P sites
noncanonical_psites_jobid=()
noncanonical_psites_jobid+=($(sbatch --parsable \
 --mem=20G \
 --cpus-per-task=4 \
 --time=24:00:00 \
 --job-name=${run}.noncanonical_psites \
 --output=log/${run}.noncanonical_psites \
 --dependency=afterok:${riboseqc_jobid} \
 ${scriptdir}/detect_ORF_overlap_psites_GENCODE_ORFEOME.sh
))

# Step 8: Merge all BAM files with SAMTOOLS
pool_jobid=()
pool_jobid+=($(sbatch --parsable \
 --mem=48G \
 --cpus-per-task=6 \
 --time=24:00:00 \
 --job-name=${run}.pooling \
 --output=log/${run}.pooling \
 --dependency=afterok:${canonical_psites_jobid} \
 ${scriptdir}/merge_bamfiles.sh
))


#Step 9: Run RiboseQC on merged BAM for overall QC statistics
riboseqc_merged_jobid=()
riboseqc_merged_jobid+=($(sbatch --parsable \
 --mem=48G \
 --cpus-per-task=6 \
 --time=24:00:00 \
 --job-name=${run}.riboseqc.pooled \
 --output=log/${run}.riboseqc.pooled \
 --dependency=afterok:${pool_jobid} \
 ${scriptdir}/merged_riboseqc.sh
))




