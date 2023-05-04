###########################################################################
#
# Authors: D.A.Hofman-3@prinsesmaximacentrum.nl
# Authors: J.T.vandinter-3@prinsesmaximacentrum.nl
# Date: 04-06-2021
#
# Description:
# Script to run RiboseQC on sample-to-sample basis
#
###########################################################################

# Load libraries ----------------------------------------------------------
message("Loading required libraries ...")
suppressPackageStartupMessages({
  library(ORFquant)
  library(RiboseQC)
  library(rmarkdown)
})

# Get variables from input ------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
bam = args[1]
targetdir = args[2]
rannot = args[3]
annot_name = args[4]
pandoc_dir = args[5]
resource_dir = args[6]
annotation_package = args[7]

# Define variables --------------------------------------------------------
find_pandoc(dir = pandoc_dir)
species = "Homo.sapiens"
package_name = paste0(resource_dir,"/BSgenome.", species, ".", annot_name)

# Define functions --------------------------------------------------------
riboseqc_analysis <- function(bam,rannot, targetdir) {

  print(bam)

  tryCatch(

    expr = {

      RiboseQC_analysis(annotation_file = rannot,
                        bam_files = bam,
                        read_subset = F,
                        readlength_choice_method = "max_coverage",
                        dest_names = targetdir,
                        rescue_all_rls = FALSE, fast_mode = F,
                        create_report = T, sample_names = NA,
                        report_file = targetdir, extended_report = F,
                        pdf_plots = T)

      message("Successfully executed the call.")

    },

    error = function(e){
      message('Caught an error!')
      print(e)
    }

  )
}

if(!require(basename(annotation_package), character.only = T)) {
  install.packages(annotation_package,
                   repos=NULL, type="source")
}

# Run script --------------------------------------------------------------
riboseqc_analysis(bam,rannot,targetdir)
