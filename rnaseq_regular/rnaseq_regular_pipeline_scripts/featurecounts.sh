#!/bin/bash

set -uo pipefail

# Load required modules
module load subread/${subread_version}
module load R/${r_version}

# Create output dir
mkdir -p "${outdir}/featurecounts"

# Check whether script needs to run
if [[ -f "${outdir}/featurecounts/${merged_gtf_basename}.counts" ]]; then
  echo "`date` Count file already present"
  exit 0
fi

# Get correct files
get_samples $wd $data_folder

# Check strandedness for downstream tools
for i in ${!sample_ids[@]}; do
  bams[i]="${outdir}/star/${sample_ids[i]}/${sample_ids[i]}.Aligned.sortedByCoord.out.bam"
  strandedness[i]=$( awk -v sid="${sample_ids[i]}" '$1 ~ sid {print $2}' ${outdir}/check_strandedness/strandedness_all.txt)
    if [[ ${strandedness[i]} == "RF/fr-firststrand" ]]; then
      strandtype[i]=2
    elif [[ ${strandedness[i]} == "FR/fr-secondstrand" ]]; then
      strandtype[i]=1
    else
      strandtype[i]=0
    fi
done

strandtype=$(IFS=,; echo "${strandtype[*]}")

echo "`date` Running featureCounts"

featureCounts -v

featureCounts \
  -s ${strandtype} \
  -T 8 \
  -p \
  -t "CDS" \
  -g "gene_id" \
  -J \
  -G ${reference_genome} \
  -a "${reference_gtf}" \
  -o "${outdir}/featurecounts/${merged_gtf_basename}.counts" \
  ${bams[@]}

echo "`date` Finished ${projectname} samples"