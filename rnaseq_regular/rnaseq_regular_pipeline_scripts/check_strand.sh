#!/bin/bash

set -uo pipefail

# Load necessary modules
module load howarewestrandedhere

# Load files
mapfile -t r1_files < r1_files.txt
mapfile -t r2_files < r2_files.txt
mapfile -t sample_ids < sample_ids.txt

r1_file="${r1_files[$((SLURM_ARRAY_TASK_ID-1))]}"
r2_file="${r2_files[$((SLURM_ARRAY_TASK_ID-1))]}"
sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"

# Create output dirs
mkdir -p "${outdir}/check_strandedness"
cd "${outdir}/check_strandedness"

# Check whether script needs to run
if [[ -s "${outdir}/check_strandedness/${sample_id}.txt" ]]; then
  echo "`date` ${sample_id} file already present"
  exit 0
fi

# Infer strandedness
check_strandedness -g ${reference_gtf} \
-n 1000000 \
-r1 ${r1_file} \
-r2 ${r2_file} \
-k "${kallisto_index}" >> "${outdir}/check_strandedness/${sample_id}.txt"

# Record strandedness
touch "${outdir}/check_strandedness/strandedness_all.txt" 
strandedness=$(tail -n 1 ${sample_id}.txt | awk 'NF>1{print $NF}')
printf "%s\t%s\n" "$sample_id" "$strandedness" >> "${outdir}/check_strandedness/strandedness_all.txt" 

echo "$(date) Finished mapping ${sample_id}"