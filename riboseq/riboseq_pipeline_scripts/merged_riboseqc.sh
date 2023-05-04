#!/bin/bash

# This bash script executes the riboseqc R script for the merged BAM file

set -uo pipefail

# Load software modules
module load R/${r_version}

# Check whether script needs to run
if [[ -f "${outdir}/RiboseQC/Medullo_merged/Medullo_merged.html" ]]; then
  echo "File already present"
  exit 0
fi

# Create output dirs
cd "${outdir}"
mkdir -p "RiboseQC/Medullo_merged/"

# Use RiboSeQC to generate HTML report of the data
Rscript "${scriptdir}/run_riboseqc.R" \
  "${outdir}/samtools/Medullo_merged/Medullo_merged.bam" \
  "${outdir}/RiboseQC/Medullo_merged/Medullo_merged" \
  "${rannot}" \
  "${annot_name}" \
  "${pandoc_dir}" \
  "${resource_dir}" \
  "${annotation_package}"