#!/bin/bash

set -euo pipefail

# Load correct modules
module load STAR/${star_version}
module load samtools/${samtools_version}

# Load files
sample_id="${sample_ids[$((SLURM_ARRAY_TASK_ID-1))]}"
r1_filtered="${outdir}/bowtie2/${sample_id}/${sample_id}_filtered.fastq.gz"

echo "`date` running STAR for ${sample_id}"

# Check whether script needs to run
if [[ -s "${outdir}/star_tx/${sample_id}/${sample_id}.Aligned.sortedByCoord.out.bam" ]]; then
  echo "$(date) ${sample_id} BAM already present"
  exit 0
fi

# Create output dirs
mkdir -p "${outdir}/star/${sample_id}/"

# Map ribo reads
STAR --genomeDir "${star_index_basedir}/29nt" \
  --sjdbGTFfile ${gtf} \
  --runThreadN 16 \
  --runDirPerm All_RWX \
  --twopassMode Basic \
  --readFilesIn "${r1_filtered}" \
  --readFilesCommand zcat \
  --outFilterMismatchNmax 2 \
  --outFilterMultimapNmax 20 \
  --outSAMattributes All \
  --outSAMtype BAM SortedByCoordinate \
  --quantMode TranscriptomeSAM \
  --outFileNamePrefix "${outdir}/star_tx/${sample_id}/${sample_id}." \
  --limitOutSJcollapsed 10000000 \
  --limitIObufferSize=300000000 \
  --outFilterType BySJout \
  --alignSJoverhangMin 1000 \
  --outTmpKeep None

samtools index -@ 16 "${outdir}/star_tx/${sample_id}/${sample_id}.Aligned.sortedByCoord.out.bam"

samtools sort -o "${outdir}/star_tx/${sample_id}/${sample_id}.Aligned.toTranscriptome.sorted.out.bam" -@ 16 "${outdir}star_tx/${sample_id}/${sample_id}.Aligned.toTranscriptome.out.bam"
samtools index -@ 16 "${outdir}star_tx/${sample_id}/${sample_id}.Aligned.toTranscriptome.sorted.out.bam"