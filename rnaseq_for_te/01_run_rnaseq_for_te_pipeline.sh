#!/bin/bash

# 01_run_rnaseq_for_te_pipeline.sh
# 
# A pipeline script for processing RNA-seq data using SLURM workload manager and lmod module system.
# The script identifies the fastq files for each sample and initiates a SLURM array to execute the pipeline steps for each sample in parallel. 
# The steps include quality control, trimming, strandedness check, alignment, and quantification.
# This pipeline is similar to the regular RNA-seq pipeline, but RNA-seq data is processed in the same way as ribo-seq data, in order to make the RNA-seq and ribo-seq data more comparable for the purpose of translational efficiency calculations.
# While the input for the regular RNA-seq pipeline consisted of the paired reads, only the first reads are used here (similar to ribo-seq). Reads are trimmed to 29 nt, to match the average length of ribo-seq reads. 
# An additional filtering step is also implemented, where reads are mapped to a list of contaminant sequences, similar to how ribo-seq reads are processed.
# The outputs of this pipeline are used to calculate translational efficiency, which is the ratio of ribo-seq reads over RNA-seq reads. # See the config_file.sh for module dependencies, version numbers, and reference files used.
# See the config_file.sh for module dependencies, version numbers, and reference files used.
#
# List of output files
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
  01_run_rnaseq_for_te_pipeline.sh [-c <config file>] [-h]
DESCRIPTION
  1. Trim reads to 29 nt and filter them with trimgalore (wrapper for cutadapt and fastqc)
  2. Run BOWTIE2 on trimmed reads to filter contaminant RNA sequences
  3. Map reads with STAR
  4. Quantify gene-level read counts for annotated CDS regions with featureCounts
  5. Generate Salmon index for ORF-level read quantification
  6. Run Salmon with custom index to quantify reads mapping to canonical and non-canonical ORFs
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

# Load configuration variables
source $CONFIG

# Load general functions
source ${scriptdir}/general_functions.sh

# Create a unique prefix for the names for this run of the pipeline. 
# This makes sure that runs can be identified
run=$(uuidgen | tr '-' ' ' | awk '{print $1}')

# Show help message if there was no config file location given on the commandline
if [[ -z $1 ]]; then usage; exit; fi

# Get correct annotation files
check_annotation ${reference_gtf} ${custom_gtf}

# Find samples
echo "$(date '+%Y-%m-%d %H:%M:%S') Finding samples..."
get_samples $project_data_folder $data_folder $paired_end

# Create output directories
mkdir -p log
mkdir -p ${outdir}

##############################################################################

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
  ${scriptdir}/trimgalore.sh
))
info "Trimgalore jobid: ${trim_jobid[@]}"


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


# Step 5: generate Salmon index for canonical and non-canonical ORFs
salmon_index_jobid=()
salmon_index_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=8 \
  --time=24:00:00 \
  --gres=tmpspace:10G \
  --job-name=${run}.salmon_index \
  --output=log/${run}/%A_salmon_index.out \
  --dependency=afterok:${star_jobid} \
  --export=ALL \
  ${scriptdir}/salmon_index.sh \
))
info "Salmon Index jobid: ${salmon_index_jobid[@]}"


# Step 6: Quantify ORF-level RNA-seq reads using Salmon
salmon_quant_jobid=()
salmon_quant_jobid+=($(sbatch --parsable \
  --mem=48G \
  --cpus-per-task=8 \
  --time=24:00:00 \
  --gres=tmpspace:50G \
  --array 1-${#samples[@]}%${simul_array_runs} \
  --job-name=${run}.salmon_quant_rna \
  --output=log/${run}/%A_salmon_quant.out \
  --dependency=afterok:${salmon_index_jobid} \
  --export=ALL \
  ${scriptdir}/salmon_quant.sh \
))
info "Salmon quant jobid: ${salmon_index_jobid[@]}"


