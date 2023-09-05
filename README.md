# Hofman et al., 2023 - Ribo-seq & RNA-seq Analysis


[![DOI](https://zenodo.org/badge/629514135.svg)](https://zenodo.org/badge/latestdoi/629514135)



## Repository Overview

This repository contains the code and resources associated with the scientific paper by Hofman et al., published in BioRxiv on May 6, 2023 (DOI: [10.1101/2023.05.04.539399](https://doi.org/10.1101/2023.05.04.539399)). The repository is maintained by @damhof and includes scripts used for the analysis presented in the paper.

## Installation

The code in this repository is primarily written in Shell (80.2%), Python (11.1%), and R (8.7%). The code was written to work with the SLURM workload manager on a HPC. To run the code, you will need to have these languages and their respective packages installed on your system. Specific dependencies may be found within individual config files in the analysis subdirectories.

## Usage

The repository is organized into several directories, each containing scripts related to a specific aspect of the analysis:

- `riboseq`: Contains scripts related to ribosome sequencing analysis.
- `rnaseq_for_te`: Contains scripts for RNA sequencing for translational efficiency.
- `rnaseq_regular`: Contains scripts for regular RNA sequencing analysis.
- `translational_efficiency`: Contains scripts related to the analysis of translational efficiency.

To run a script, navigate to its respective directory and execute it from the command line. Ensure that all required inputs are available and correctly formatted. The specific usage instructions and expected outputs can be found within the comments of each script.


## Additional Resources

At the time of this writing, no additional resources such as datasets or pre-trained models are provided directly in the repository. However, the paper associated with this repository references external resources used in the analysis.

## Citation

To cite the work associated with this repository, please use the following citation:

```
Hofman et al., BioRxiv, May 6, 2023, DOI: 10.1101/2023.05.04.539399
```

This README provides a general overview and guide to the repository. For specific details, users are encouraged to explore the scripts and resources within the repository and refer to the associated scientific paper.
