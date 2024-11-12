# Create lookup tables of state names and abbreviations
library(tidyverse)

# Get data saved locally
egm_table = read_csv("./data-raw/egm_dict.csv") |>
  mutate_all(as.character) 

# Create dictionary tibble
egm_dict_tbl =
  egm_table |>
  pivot_longer(
    -venue_abbr,
    names_to = "type",
    values_to = "alias")

# egm_abbr type to above
egm_dict_tbl =
  bind_rows(
    egm_dict_tbl,
    egm_table |>
      select(venue_abbr) %>%
      mutate(alias = venue_abbr,
             type = "venue_abbr")
  )

# create dictionary as character vector
egm_dict <- egm_dict_tbl$alias
names(egm_dict) <- egm_dict_tbl$venue_abbr

# Add known missing cases
egm_dict <- c(egm_dict)

# Add no spaced versions
nospaces <- str_remove_all(egm_table$venue_name, " ")
names(nospaces) <- egm_table$venue_abbr

egm_dict <- c(egm_dict, nospaces)

# remove duplicates
egm_dict <- egm_dict[!duplicated(egm_dict)]

egm_dict <- tolower(egm_dict)

usethis::use_data(egm_dict, egm_table, overwrite = TRUE, internal = TRUE)
