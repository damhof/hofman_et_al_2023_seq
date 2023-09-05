#!/bin/bash

# This bash script executes the riboseqc R script with the correct files and parameters

set -uo pipefail

# Load correct modules
module load R/${r_version}

# Load files
mapfile -t sample_ids < sample_ids.txt

sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"
bam_file="${outdir}/star_tx/${sample_id}/${sample_id}.Aligned.sortedByCoord.out.bam" \

# Check whether script needs to run
if [[ -f "${outdir}/RiboseQC/${sample_id}/${sample_id}.html" ]]; then
  echo "File already present"
  exit 0
fi

# Create output dirs
cd "${outdir}/"
mkdir -p "RiboseQC/${sample_id}"

# Use RiboSeQC to generate HTML report of the data
Rscript "${scriptdir}/run_riboseqc.R" \
  "${bam_file}" \
  "${outdir}/RiboseQC/${sample_id}/${sample_id}" \
  "${rannot}" \
  "${annot_name}" \
  "${pandoc_dir}" \
  "${resource_dir}" \
  "${annotation_package}"