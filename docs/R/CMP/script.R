# This script calls the 'template.Rmd' file for each CMP scenario

# Load libraries
library(tidyverse)
library(readxl)
library(rmarkdown)

# Set up common directories
model_dir <- normalizePath("../../..")
cmp_dir <- normalizePath(paste0(model_dir, "/scenarios/CMP_2016"))
out_dir <- paste0(model_dir, "/docs") # where html pages are written

# project info table
proj_info <- read_excel(
  paste0(model_dir, "/Project Management Tool.xlsx"), skip = 8
)
proj_info <- proj_info[, 1:12]
proj_info <- proj_info %>%
  select(-c(`TIP ID`, `PROJECT NO 2040`, `Project Status (@2012)`, FROM, TO))

# read the list of non-ec projects
non_ec <- read_csv(paste0(cmp_dir, "/non_ec_project_list.csv"))

# purp equiv table
purp_labels <- c("HBW", "HBSC", "HBU", "HBES", "HBO", "NHB", "Total")
purp_equiv <- data_frame(
  purp_num = c(-1, 0, 1, 2, 3, 4, 5, 6),
  purp_name = c("HB", "W", "U", "SC", "ES", "O", "O", "WB")
)

# mode equiv table
mode_labels <- c(
  "Drive Alone",
  "Drive 2",
  "Drive 3+",
  "Walk",
  "Bike",
  "Walk to Local Bus",
  "Walk to Express Bus",
  "Walk to Rail",
  "Kiss-and-Ride",
  "Informal PNR",
  "Formal PNR",
  "School Bus",
  "Total"
) 
mode_equiv <- data_frame(
  mode_num = c(1, 3, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 99),
  mode_name = mode_labels
)

# create a function to summarize the trips.csv table
summarize_mc <- function(trips){
  
  # summarizing the trip table
  trips %>%
    
    # create prod/attr fields
    mutate(
      prod_purp = ifelse(
        destinationPurpose == -1, destinationPurpose, originPurpose
      ),
      attr_purp = ifelse(
        destinationPurpose == -1, originPurpose, destinationPurpose
      )
    ) %>%
    
    # translate purpose codes
    left_join(purp_equiv, by = c("prod_purp" = "purp_num")) %>%
    select(-prod_purp) %>%
    rename(prod_purp = purp_name) %>%
    left_join(purp_equiv, by = c("attr_purp" = "purp_num")) %>%
    select(-attr_purp) %>%
    rename(attr_purp = purp_name) %>%
    
    # create trip purpose
    mutate(
      trip_purp = ifelse(
        prod_purp == "WB" | attr_purp == "WB", "NHB", paste0(prod_purp, attr_purp)
      ),
      trip_purp = ifelse(
        prod_purp != "HB" & attr_purp != "HB", "NHB", trip_purp
      )
    ) %>%
    
    # translate modes
    left_join(mode_equiv, by = c("tripMode" = "mode_num")) %>%
    
    # group and summarize
    group_by(trip_purp, mode_name) %>%
    summarize(trips = sum(expansionFactor)) %>%
    ungroup() %>%
    
    # sort
    mutate(
      mode_name = factor(mode_name, levels = mode_labels, ordered = TRUE),
      trip_purp = factor(trip_purp, levels = purp_labels, ordered = TRUE)
    )
}

# This function is used to create two-dimension sum marginals on
# many of the summary tables in template.Rmd
marg_2d <- function(table, d1, d2){
  
  tbl1 <- table %>%
    group_by_(d1) %>%
    summarize(ec = sum(ec), project = sum(project))
  tbl1[, d2] <- "Total"
  
  new_table <- bind_rows(table, tbl1)
  
  tbl2 <- new_table %>%
    group_by_(d2) %>%
    summarize(ec = sum(ec), project = sum(project))
  tbl2[, d1] <- "Total"
  
  new_table <- bind_rows(new_table, tbl2)
}

# read in and process ec-related data once to reduce build time
ec_dir <- paste0(cmp_dir, "/EC")
ec_trips <- read_csv(paste0(ec_dir, "/outputs/trips.csv"))
ec_mc_summary <- summarize_mc(ec_trips) %>%
  mutate(Scenario = "ec")

# Looping over each project and creating pages
for (id in non_ec$ProjID){
  
  # Create a vector of representative link IDs. These IDs are used
  # to measure changes in point volume and V/C
  rep_links <- non_ec %>%
    filter(ProjID == id) %>%
    select(rep_link)
  rep_links <- as.character(rep_links[1]) %>%
    strsplit(., ";") %>%
    unlist()
  
  rmarkdown::render(
    "template.Rmd",
    output_file = paste0("cmp_proj_", id, ".html"),
    output_dir = out_dir,
    output_format = "html_document"
  )
}