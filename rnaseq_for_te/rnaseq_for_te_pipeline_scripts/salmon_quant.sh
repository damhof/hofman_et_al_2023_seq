#!/bin/bash

# This script quantifies reads mapping to ORFs using Salmon

set -uo pipefail

# Load modules
module load salmon/1.8.0

# Load files
mapfile -t sample_ids < sample_ids.txt

sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"
r1_filtered="${outdir}/bowtie2/${sample_id}/${sample_id}_filtered.fastq.gz"
index="${outdir}/salmon_index/MANE_GENCODE_ORFEOME_CDS/"

mkdir -p "${outdir}/salmon_quant/${sample_id}/"

echo "`date` Running salmon for ${sample_id}"

# Run salmon for transcript counts
salmon quant \
  --libType "A" \
  --validateMappings \
  --gcBias \
  --quiet \
  --numGibbsSamples 30 \
  --threads 6 \
  -i "${index}" \
  -r "${r1_filtered}" \
  --output "${outdir}/salmon_quant/${sample_id}/"
  
echo "`date` Finished salmon ${sample_id}"