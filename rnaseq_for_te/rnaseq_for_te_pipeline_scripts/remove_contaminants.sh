#!/bin/bash

# This script removes contaminants from RNA-seq reads using Bowtie2

set -uo pipefail  # Enable strict mode

# Load correct modules
module load bowtie2/${bowtie2_version}
module load samtools/${samtools_version}

# Get input file and sample ID
r1_file="${r1_files[$((SLURM_ARRAY_TASK_ID-1))]}"
sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"
r1_filename=$(basename ${r1_file})
r1_trimmed="${r1_filename/_R1_/R1_trimmed_}"

# Check if script has already been run
if [[ -s "${outdir}/bowtie2/${sample_id}/${sample_id}_contaminants" ]]; then
  echo "Contaminants have already been removed for ${sample_id}"
  exit 0
fi

# Create output dirs
cd "${outdir}"
mkdir -p "bowtie2/${sample_id}"

# Run Bowtie2 to remove contaminants
bowtie2 --seedlen=25 \
  --threads 6 \
  --time \
  --un-gz "${outdir}/bowtie2/${sample_id}/${sample_id}_filtered.fastq.gz" \
  -x ${bowtie2_index} \
  -U "${outdir}/trimgalore/${sample_id}/${r1_trimmed}" \
  -S "${outdir}/bowtie2/${sample_id}/${sample_id}_contaminants"

# Create contaminant QC file
echo "$(date) Creating QC file for ${sample_id}" 
tot_reads=$(zcat "${outdir}/trimgalore/${sample_id}/${r1_trimmed}" | echo $((`wc -l`/4)))  # Count total number of reads
printf "Contaminant QC run for ${sample_id} on %s\n\n" "$(date)" >> "${outdir}/bowtie2/${sample_id}_contaminants.txt"
printf '\t%s\t%s\t%s\n' "READ_TYPE" "READS" "PERCENTAGE" >> "${outdir}/bowtie2/${sample_id}_contaminants.txt"  # Print headers
printf "%s\t%s\t%s\t%s\n" "${sample_id}" "Total" $tot_reads "100" >> "${outdir}/bowtie2/${sample_id}_contaminants.txt"  # Print total reads

for contaminant_type in tRNA snRNA snoRNA mtDNA rRNA ; do  
  contaminant_reads=`samtools view "${outdir}/bowtie2/${sample_id}/${sample_id}_contaminants" | grep -o "$contaminant_type" | wc -l`
  contaminant_percentage=`awk -vn=248 "BEGIN{print(${contaminant_reads}/${tot_reads}*100)}"`
  printf '%s\t%s\t%s\t%s\n' "${sample_id}" "${contaminant_type}" "${contaminant_reads}" "${contaminant_percentage}" >> "${outdir}/bowtie2/${sample_id}_contaminants.txt"
done

filtered_reads=$(zcat "${outdir}/bowtie2/${sample_id}/${sample_id}_filtered.fastq.gz" | echo $((`wc -l`/4)))  # Count reads that passed filtering
filtered_percentage=`awk -vn=248 "BEGIN{print(${filtered_reads}/${tot_reads}*100)}"`
printf '%s\t%s\t%s\t%s\n\n' "${sample_id}" "Passed" "${filtered_reads}" "${filtered_percentage}" >> "${outdir}/bowtie2/${sample_id}contaminants.txt"

echo "`date` Finished ${sample_id}"