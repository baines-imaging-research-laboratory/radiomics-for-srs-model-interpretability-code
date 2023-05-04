# radiomics-for-srs-model-interpretability-code
Open-source code associated with the results presented in the manuscript "Assessment of Brain Metastasis Qualitative Appearance Interobserver Variability and Comparison to MRI Radiomics for Stereotactic Radiosurgery Outcome Prediction"

## Code Description
The experiments and analysis described in the manuscript were performed in a number of discrete steps. Each step is contained with a separate folder within this repository. The "main.m" file within each folder contains the code performed, with any other reference code contained within the "Code" folder. "codepaths.txt" and "datapaths.txt" contain references to the code and data used by each "main.m". "Experiment.m" contains a class allowing for completely reproducible execution of the "main.m" code, including random number generation regardless of a single processor or multi-processor (local or distributed) computation environment. To run each "main.m", the current directory should be set to the folder containing the "main.m" file in question, and then "Experiment.Run()" should be executed. "settings.mat" contains setting for the Experiment class that can be adjusted without impacting the computation results (e.g. single vs. multi-processor execution).

## Experiment Manifest
The "Experiment Manifest.xlsx" file within the root of this repository contains an exhaustive list of all the experiments and analysis performed in the manuscript, which also acts as roadmap to the folder structure of this repository. This manifest also shows the dependence of the experiments and analysis on one another to show the order in which each experiment was performed.

## Contact Information
Author: David A. DeVries

Email: ddevrie8@uwo.ca

Organization: Western University/London Health Sciences Centre, London ON CA