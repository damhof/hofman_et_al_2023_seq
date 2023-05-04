#!/bin/bash

set -uo pipefail

# Load correct modules
module load cutadapt/${cutadapt_version}
module load fastqc/${fastqc_version}
module load trimgalore/${trimgalore_version}

# Load files
r1_file="${r1_files[$((SLURM_ARRAY_TASK_ID-1))]}"

# Set names
sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"
r1_filename=$(basename ${r1_file})

# Create output dirs
cd "${outdir}"
mkdir -p "trimgalore/${sample_id}/"

# Check whether script needs to run
if [[ -f "${outdir}/trimgalore/${sample_id}/${r1_filename}" ]]; then
  echo "`date` ${sample_id} file already present"
  exit 0
fi

# Run trimgalore
echo "`date` Trimming reads ${sample_id}"
cutadapt --version
fastqc --version

# Change names of trimgalore output
cd "${outdir}/trimgalore/${sample_id}/"

trim_galore "${r1_file}" \
  --cores 2 \
  --gzip \
  --length 25 \
  --trim-n \
  --fastqc \
  --fastqc_args "--outdir ${outdir}/trimgalore/${sample_id}/" \
  --output_dir "${outdir}/trimgalore/${sample_id}/"

# Change names of validated trimgalore output to basename
r1_trimmed="${r1_filename/_R1_/R1_trimmed_}"

mv "${outdir}/trimgalore/${sample_id}/${r1_filename%.*.*}.29bp_5prime_trimmed.fq.gz" "${outdir}/trimgalore/${sample_id}/${r1_trimmed}"

# Calculate trimcounts per paired fastq
tot_reads=$(zcat "${full_path_fastq_1}" | echo $((`wc -l`/4)))
trimmed_reads=$(zcat "${outdir}/trimgalore/${sample_id}/${r1_trimmed}" | echo $((`wc -l`/4)))
trimmed_percentage=`awk -vn=248 "BEGIN{print(${trimmed_reads}/${tot_reads}*100)}"`

# Add read trimming info to run QC file
printf '%s\t%s\t%s\t%s\n' "${sample_id}" "Trimmed" $trimmed_reads $trimmed_percentage >> "${outdir}/trim_stats.txt"

echo "`date` Finished ${sample_id}"