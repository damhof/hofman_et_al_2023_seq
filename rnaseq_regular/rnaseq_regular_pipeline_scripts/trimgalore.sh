#!/bin/bash

set -uo pipefail

# Load modules
module load cutadapt/${cutadapt_version}
module load fastqc/${fastqc_version}
module load trimgalore/${trimgalore_version}

# Load files
mapfile -t r1_files < r1_files.txt
mapfile -t r2_files < r2_files.txt
mapfile -t sample_ids < sample_ids.txt

r1_file="${r1_files[$((SLURM_ARRAY_TASK_ID-1))]}"
r2_file="${r2_files[$((SLURM_ARRAY_TASK_ID-1))]}"

# Set names
sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"
r1_filename=$(basename ${r1_file})
r2_filename=$(basename ${r2_file})

# Create output dirs
cd "${outdir}"
mkdir -p "trimgalore/${sample_id}/"

# Check whether script needs to run
if [[ -f "${outdir}/trimgalore/${sample_id}/${r1_filename}" ]]; then
  echo "`date` ${sample_id} file already present"
  exit 0
fi

# Run trimgalore on both reads
echo "`date` running trimgalore for ${sample_id}"
cutadapt --version
fastqc --version

cd "${outdir}/trimgalore/${sample_id}/"

trim_galore "${r1_file}" "${r2_file}" \
  --cores 2 \
  --paired \
  --gzip \
  --fastqc \
  --fastqc_args "--outdir ${outdir}/trimgalore/${sample_id}/" \
  --output_dir "${outdir}/trimgalore/${sample_id}"

# Change names of validated trimgalore output to basename
r1_trimmed="${r1_filename/_R1_/R1_trimmed_}"
r2_trimmed="${r2_filename/_R2_/R2_trimmed_}"

mv "${outdir}/trimgalore/${sample_id}/${r1_filename%.*.*}_val_1.fq.gz" "${outdir}/trimgalore/${sample_id}/${r1_trimmed}"
mv "${outdir}/trimgalore/${sample_id}/${r2_filename%.*.*}_val_2.fq.gz" "${outdir}/trimgalore/${sample_id}/${r2_trimmed}"

# Calculate trimcounts per paired fastq
tot_reads=$(zcat "${r1_file}" | echo $((`wc -l`/4)))
trimmed_reads=$(zcat "${outdir}/trimgalore/${sample_id}/${r1_trimmed}" | echo $((`wc -l`/4)))
trimmed_percentage=`awk -vn=248 "BEGIN{print(${trimmed_reads}/${tot_reads}*100)}"`

# Add read trimming info to run QC file
printf '%s\t%s\t%s\t%s\n' "${sample_id}" "Trimmed" $trimmed_reads $trimmed_percentage >> "${outdir}/trim_stats.txt"

echo "$(date) ${sample_id}: Finished trimgalore"