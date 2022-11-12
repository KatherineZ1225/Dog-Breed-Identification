## Project Directory Structure
```
|--DOg Breed Identification               <- Project root level that is checked into github
  |--project                              <- Project folder
    |--README.md                          <- Top-level README for developers
    |--volume
    |   |--data
    |   |   |--external                   <- Data from third party sources
    |   |   |--interim                    <- Intermediate data that has been transformed
    |   |   |--processed                  <- The final model-ready data
    |   |   |--raw                        <- The original data dump
    |   |
    |   |--models                         <- Trained model files that can be read into R or Python
    |
    |--required
    |   |--requirements.txt               <- The required libraries for reproducing the Python environment
    |   |--requirements.r                 <- The required libraries for reproducing the R environment
    |
    |
    |--src
    |   |
    |   |--features                       <- Scripts for turning raw and external data into model-ready data
    |   |   |--Make_fake_data.r
    |   |   |--make_wine_dt.r
    |   |
    |   |--models                         <- Scripts for training and saving models
    |   |   |--PCA.r
    |   |   |--PCA_tSNE_GMM.r
    |   |   |--model copy-copy.r
    |   |
    |
    |
    |
    |--.getignore                         <- List of files not to sync with github
```
