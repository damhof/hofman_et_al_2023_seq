#!/bin/bash

######################################################################
#
# Authors: J.T.vandinter-3@prinsesmaximacentrum.nl
# Authors: D.A.Hofman-3@prinsesmaximacentrum.nl
# Date: 04-06-2021
#
######################################################################

# Load software modules
module load samtools/${samtools_version}

# Check whether script needs to run
if [[ -f "${outdir}/samtools/Medullo_merged/Medullo_merged.bam" ]]; then
  echo "File already present"
  exit 0
fi

# Create output dirs
cd "${outdir}"
mkdir -p samtools/Medullo_merged

# Find bam files to merge
bams=$(find "${outdir}/star_tx/" -maxdepth 3 -name "*.Aligned.sortedByCoord.out.bam" -print)

# Merge bams
echo -e "\n `date` Merging bam files ..."
samtools merge -@ 6 "${outdir}/samtools/Medullo_merged/Medullo_merged.bam" ${bams[@]}
echo -e "\n `date` Merging bam files ... complete! "