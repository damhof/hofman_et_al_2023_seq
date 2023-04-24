#!/bin/bash

set -uo pipefail

# Load necessary modules
module load samtools/${samtools_version}

# Get correct files
sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"
bam="${sample_id}.Aligned.out.bam"
new_bam="${sample_id}.Aligned.sortedByCoord.out.bam"

echo "`date` running samtools for ${sample_id}"

# Check whether script needs to run
if [[ -f "${outdir}/star/${sample_id}/${new_bam}.bai" ]]; then
  echo "`date` ${sample_id} BAM index already present"
  exit 0
fi

if ! [[ -s "${outdir}/star/${sample_id}/${bam}" ]]; then
  echo "${sample_id} BAM file is empty. Re-run STAR."
  exit 1
fi

# Sort BAM
samtools sort \
  -@ 8 \
  -l 9 \
  -o "${outdir}/star/${sample_id}/${new_bam}" \
  -T "${TMPDIR}" \
  "${outdir}/star/${sample_id}/${bam}"

# Create mapping statistics with samtools
samtools stats -@ 8 \
  "${outdir}/star/${sample_id}/${new_bam}" > "${outdir}/star/${sample_id}/${sample_id}_stats.txt"

# Index the bam with samtools
samtools --version
samtools index -@ 8 "${outdir}/star/${sample_id}/${new_bam}"

# Remove original STAR bam
if [[ -s "${outdir}/star/${sample_id}/${new_bam}" ]]; then
  rm "${outdir}/star/${sample_id}/${bam}"
fi

echo "`date` finished indexing ${sample_id}"
