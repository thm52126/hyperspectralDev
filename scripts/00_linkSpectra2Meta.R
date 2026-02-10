#'------------------------------------------------------------------------------
#' @title Spectral raw data processing
#'------------------------------------------------------------------------------

#' @description Scripts to input spectra files or spectra objects and metadata
#' and export matrices in csv of raw reflectance data. This script was taken 
#' from https://github.com/Erythroxylum/herbarium-spectra/tree/main and modified 
#' for use at ICTB by Thomas Murphy. 
#' 
#'------------------------------------------------------------------------------
#' @Library
#-------------------------------------------------------------------------------
library(readr)
library(spectrolab)
library(shiny)
library(dplyr)
library(tools)
library(data.table)
library(tidyr)

#'------------------------------------------------------------------------------
#' @Working_directory
#-------------------------------------------------------------------------------

# set wd
wd = "C:/Users/thm52/Documents/Lauraceae_spec/"
setwd(wd)

#'------------------------------------------------------------------------------
#' @Process-Herbarium-Spectra
#-------------------------------------------------------------------------------

# Spectral data within directory

path_refl = "C:/Users/thm52/Documents/Lauraceae_spec/all/"
data_refl = spectrolab::read_spectra(path = path_refl,
                                     format="sed", 
                                     extract_metadata = TRUE)

####### get filenames
# Specify the path to the directory containing your spectra files
data_dir <- "C:/Users/thm52/Documents/Lauraceae_spec/all/"

# List all the files in the directory
file_list <- list.files(path = data_dir, 
                        pattern = "\\.sed$", 
                        full.names = TRUE)

###############################
#  match sensor overlap

## Guess "good" splicing bands
splice_guess = spectrolab::guess_splice_at(data_refl)
splice_guess
## Viz the spectra and confirm that the splicing bands make sense
#spectrolab::plot_interactive(data_refl)

# Pick the final splicing bands. Could be the same as `splice_guess`
# Dawson did this by selecting the right side of the break. Worked.
splice_at = c(689, 1877)

# Finally, match the sensor overlap, interpolate_wv=extent around splice_at values over which the splicing factors will be calculated.
data_refl = spectrolab::match_sensors(x = data_refl, 
                                      splice_at = splice_at, 
                                      interpolate_wvl = c(5, 1))


###############################
# Match metadata and spectra

# set spectral data
spectra <- data_refl

# Extract just the base filenames (without directory path and extension)
names(spectra) <- tools::file_path_sans_ext(basename(file_list))
#names(spectra_norm) <- tools::file_path_sans_ext(basename(file_list))



# Read metadata spreadsheet
meta_Kyra <- readr::read_csv("C:/Users/thm52/Documents/Lauraceae_spec/meta/meta_Kyra_29Jan2026.csv")
meta_Nellie <- readr::read_csv("C:/Users/thm52/Documents/Lauraceae_spec/meta/meta_Nellie_29Jan2026.csv")

#combine tables based on column name
meta<-bind_rows(meta_Kyra,
                meta_Nellie)

#remove rows with NA for a column that should always have data
meta_clean <- meta %>%
  drop_na(simpleFilename)


# Get spectra names (without file extension)
spectra_names <- names(spectra)
spectra_base <- tools::file_path_sans_ext(basename(spectra_names))

# Match metadata rows using filename (no extension)
metadata_base <- tools::file_path_sans_ext(meta_clean$filename)
match_idx <- match(spectra_base, 
                   metadata_base)

# Reorder metadata to match spectra
metadata_matched <- meta_clean[match_idx, ]

# Combine metadata and spectra into one data frame
spectra_matrix <- as.data.frame(as.matrix(spectra))  # convert spectra to numeric matrix
full_data <- cbind(metadata_matched, 
                   spectra_matrix)

# Make sure data looks ok.
View(full_data)

# Write to CSV
write.csv(full_data, file = "THM_LAUR_RAW_noResample_350-2500_02022026.csv")

#-------------------------------------------------------------------------------
#' @End
#-------------------------------------------------------------------------------
