#!/bin/sh -l

# Install R
echo "\e[1mInstalling R and dependencies"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y r-base
apt-get install -y r-base r-base-dev r-cran-xml r-cran-rmarkdown libcurl4-openssl-dev
apt-get install -y libssl-dev libxml2-dev
apt-get install -y xml2 pandoc
apt-get install -y r-cran-tidyverse r-cran-domc r-cran-glmnet r-cran-rms r-cran-corrplot 

echo "\e[33m\e[1mR session information"
Rscript -e 'sessionInfo()'

# Check for build only
if [ "$1" = "build" ]; then
    echo "\e[33m\e[1mRunning only build task"
    R CMD build --no-build-vignettes ./
fi

# Build and check
if [ "$1" = "all" ]; then
    echo "\e[33m\e[1mRunning all tasks"
    echo "\e[33m\e[1mStart package build."
    R CMD build ./
    echo "\e[33m\e[1mPackage build ended."
    # Check if description file exist
    if [ -f DESCRIPTION ]; then
        echo "\e[33m\e[1mDESCRIPTION exist."
        echo "\e[33m\e[1mInstall texlive for PDF manual check."
        apt-get -y install texlive

        # Check for bioconductor dependencies
        if [ "$2" = true ]; then
            echo "\e[33m\e[1mInstall Bioconductor"
            Rscript -e 'if (!requireNamespace("BiocManager", quietly=TRUE))  install.packages("BiocManager");if (FALSE) BiocManager::install(version = "devel", ask = FALSE);cat(append = TRUE, file = "~/.Rprofile.site", "options(repos = BiocManager::repositories());")'
            
            echo "\e[33m\e[1mInstall package dependencies."
            Rscript -e 'if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", repo = c(BiocManager::repositories()))'
            Rscript -e 'deps <- remotes::dev_package_deps(dependencies = NA, repos = c(BiocManager::repositories()));remotes::install_deps(dependencies = TRUE, repos = c(BiocManager::repositories()));if (!all(deps$package %in% installed.packages())) { message("missing: ", paste(setdiff(deps$package, installed.packages(repo=)), collapse=", ")); q(status = 1, save = "no")}'
        else
            echo "\e[33m\e[1mInstall package dependencies."
            Rscript -e 'if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")'
            Rscript -e 'deps <- remotes::dev_package_deps(dependencies = NA);remotes::install_deps(dependencies = TRUE);if (!all(deps$package %in% installed.packages())) { message("missing: ", paste(setdiff(deps$package, installed.packages(repo=)), collapse=", ")); q(status = 1, save = "no")}'
        fi

        echo "\e[33m\e[1mGet package name and version from description file."
        package=$(grep -Po 'Package:(.*)' DESCRIPTION)
        version=$(grep -Po 'Version:(.*)' DESCRIPTION)
        package=${package##Package: }
        version=${version##Version: }

        echo "\e[33m\e[1mStart package check and test for ${package}_${version}"
        if [ -f "${package}_${version}.tar.gz" ]; then
            R CMD check ./"${package}_${version}.tar.gz" --as-cran
        else 
            echo "\e[31m\e[1mPackage did not build properly, no package to test."
            # exit 1 
        fi
    else 
        echo "\e[31m\e[1mDESCRIPTION file does not exist."
        exit 1
    fi
fi
