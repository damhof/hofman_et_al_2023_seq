
suppressPackageStartupMessages({
    library(RiboseQC)
})

args = commandArgs(trailingOnly=TRUE)

riboseqc_file <- args[1]
outdir <- args[2]

fname <- gsub(pattern = "_for_ORFquant", x = basename(riboseqc_file), replacement = "")

load(riboseqc_file)

P_sites <- data.frame(for_ORFquant$P_sites_uniq)
bed <- data.frame(P_sites$seqnames, P_sites$start, P_sites$end, ".", P_sites$score, P_sites$strand)
colnames(bed) <- c("chrom", "chromStart", "chromEnd", "name", "score", "strand")

data.table::fwrite(bed, paste0(outdir, fname, "_psites.bed"), quote = F, sep = "\t", col.names = F, row.names = F)