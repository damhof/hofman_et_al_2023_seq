#!/bin/bash

# Load required modules
module load bedtools R/4.2.1 python

# Set input variables
orf_gtf="/hpc/pmc_vanheesch/projects/Damon/Medulloblastoma_analyses_final/annotation_files/GENCODEpI_plus_ORFEOME3.bed.orfs_new.gtf"  # GTF file containing ORF definitions (eg CDS regions)
is_anno="no"  # Is orf_GTF an annotation file with incomplete ORFs? (i.e. from Ensembl) [yes/no]
out_dir="${outdir}/psite_quantification/Medullo_all_Psites_quant_GENCODEp1_plus_ORFEOME"  # Directory to output generated files
riboseqc_dir="${outdir}/RiboseQC/"  # Parent directory containing RiboseQC results of all samples
analysis_name="Medullo_all_Psites_quant_GENCODEp1_plus_ORFEOME"  # Name of analysis run
id_type="orf_id"

# Display the input settings
echo -e "Running detect_ORF_overlap_psites.sh with input \n\t - ${orf_gtf} \n\t - ${is_anno} \n\t - ${out_dir} \n\t - ${riboseqc_dir} \n\t - ${analysis_name}\n"

# Prepare output directory
bedfiles_dir="${out_dir}/bedfiles/"
mkdir -p "${bedfiles_dir}"

# Functions

# generate_ref_psite_files: Generate reference P-site files if they do not exist
#   $1: ORF GTF file path
#   $2: Whether the input GTF is an annotation file with incomplete ORFs
#   $3: Output directory for the generated bed files
#   $4: Type of definitions in GTF file (transcript_ids, or ORF_ids. ORF_ids usually only for custom GTF files)
generate_ref_psite_files() {
  local orf_gtf=$1
  local is_annotation=$2
  local bedfiles_dir=$3
  local id_type=$4

  local ref_base=$(basename ${orf_gtf} .gtf)

  if [ -f "${bedfiles_dir}/${ref_base}.gtf_psites_p0.sorted.bed" ]; then
    return
  fi

  # Extract P sites
  python3 ${scriptdir}/calculate_psite_coords_final.py -i ${orf_gtf} -a "${is_annotation}" -o "${bedfiles_dir}/" -t "${id_type}"

  # Sort resulting bed file
  sort -k1,1 -k2,2n "${bedfiles_dir}/${ref_base}.gtf_psites_plus_partial.bed" > "${bedfiles_dir}/${ref_base}.gtf_psites_p0.sorted.bed"
}

# generate_sample_psite_files: Generate sample P-site files if they do not exist
#   $1: Sample file path
#   $2: Output directory for the generated bed files
generate_sample_psite_files() {
  local sample=$1
  local bedfiles_dir=$2

  local bed_base=$(basename "${sample}" _for_ORFquant)

  if [ -f "${bedfiles_dir}/${bed_base}_psites.sorted.bed" ]; then
    return
  fi

  Rscript ${scriptdir}/psites_bed_from_riboseqc.R ${sample} ${bedfiles_dir}
  sort -k1,1 -k2,2n "${bedfiles_dir}/${bed_base}_psites.bed" > "${bedfiles_dir}/${bed_base}_psites.sorted.bed"
}

# intersect_psite_files: Intersect sample P-site files with reference P-site files
#   $1: Sample bed base name
#   $2: Reference bed base name
#   $3: Output directory for the generated bed files
intersect_psite_files() {
  local bed_base=$1
  local ref_base=$2
  local bedfiles_dir=$3

  bedtools intersect -a "${bedfiles_dir}/${bed_base}_psites.sorted.bed" -b "${bedfiles_dir}/${ref_base}.gtf_psites_p0.sorted.bed" -wa -wb -header -f 1.00 -s > "${bedfiles_dir}/${bed_base}_intersect.bed"
}

# Main script

# Generate reference P-site files
generate_ref_psite_files "${orf_gtf}" "${is_anno}" "${bedfiles_dir}" "${id_type}"

# Find sample files
samples=($(find ${riboseqc_parent_dir} -maxdepth 3 -name "*_for_ORFquant"))

# Generate sample P-site files and intersect with reference P-site files
ref_base=$(basename ${orf_gtf} .gtf)
for sample in ${samples[@]}; do
  generate_sample_psite_files "${sample}" "${bedfiles_dir}"
  bed_base=$(basename "${sample}" _for_ORFquant)
  intersect_psite_files "${bed_base}" "${ref_base}" "${bedfiles_dir}"
done

# Calculate P-sites per codon matrix
echo -e "\nCalculating P sites per codon matrix ... "
Rscript ${scriptdir}/calculate_psites_percodon_p_all.R "${bedfiles_dir}/${ref_base}.gtf_psites_plus_partial.bed" "${bedfiles_dir}" "${out_dir}" "${analysis_name}"

# Finish
echo "Done!"