#!/bin/bash

set -uo pipefail

# Load correct modules
module load STAR/${star_version}

# Load files
mapfile -t r1_files < r1_files.txt
mapfile -t r2_files < r2_files.txt
mapfile -t sample_ids < sample_ids.txt

r1_file="${r1_files[$((SLURM_ARRAY_TASK_ID-1))]}"
r2_file="${r2_files[$((SLURM_ARRAY_TASK_ID-1))]}"
sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"

new_bam="${sample_id}.Aligned.sortedByCoord.out.bam"
r1_filename=$(basename ${r1_file})
r2_filename=$(basename ${r2_file})
r1_trimmed="${r1_filename/_R1_/R1_trimmed_}"
r2_trimmed="${r2_filename/_R2_/R2_trimmed_}"

# Create output dirs
cd "${outdir}"
mkdir -p "star/${sample_id}/"

echo "`date` running STAR for ${sample_id}"

# Check whether script needs to run
if [[ -s "${outdir}/star/${sample_id}/${sample_id}.Aligned.out.bam" ]]; then
  echo "`date` ${sample_id} BAM already present"
  exit 0
elif [[ -s "${outdir}/star/${sample_id}/${sample_id}.Aligned.sortedByCoord.out.bam.bai" ]]; then
  echo "`date` ${sample_id} BAM index already present"
  exit 0
fi

# Check first 10k reads for read length for star index
read_length=$(gunzip -c "${r1_file}" | \
  head -n 10000 | \
  awk '{if(NR%4==2) {count++; bases += length} } END{print bases/count - 1}')

# Make sure read length picks are correct
if [[ "${read_length}" =~ "." ]]; then
  read_length=${read_length%.*}
fi

if (( ${read_length} >= 70 && ${read_length} <= 85 )); then
  used_index=74
elif (( ${read_length} >= 86 && ${read_length} <= 111 )); then
  used_index=99
elif (( ${read_length} >= 112 && ${read_length} <= 137 )); then
  used_index=124
elif (( ${read_length} >= 138 && ${read_length} <= 163 )); then
  used_index=149
else
  used_index=99
fi

# Use STAR for mapping the reads
STAR --version
STAR --genomeDir "${star_index_basedir}/${used_index}nt" \
  --sjdbGTFfile ${reference_gtf} \
  --readFilesIn "${outdir}/trimgalore/${sample_id}/${r1_trimmed}" "${outdir}/trimgalore/${sample_id}/${r2_trimmed}" \
  --readFilesCommand zcat \
  --twopassMode Basic \
  --runThreadN 16 \
  --runDirPerm All_RWX \
  --outSAMattrRGline ID:${sample_id} LB:${sample_id} PL:IllUMINA SM:${sample_id}   \
  --outFilterType BySJout \
  --outSAMunmapped Within \
  --outSAMattributes NH HI AS nM NM MD jM jI MC ch \
  --outSAMstrandField intronMotif \
  --outSAMtype BAM Unsorted \
  --outFileNamePrefix "${outdir}/star/${sample_id}/${sample_id}." \
  --outFilterMismatchNmax 6 \
  --outTmpKeep None \
  --alignSJoverhangMin 10 \
  --outFilterMultimapNmax 10 \
  --outFilterScoreMinOverLread 0.75

  echo "`date` finished mapping ${sample_id}"
