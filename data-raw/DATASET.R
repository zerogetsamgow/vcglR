## code to prepare `egm_venue_data` 

library(tidyverse)
library(rvest)

egm_venue_data = 
  # Get html from following url and extract hrefs for xlsx files
  "https://www.vgccc.vic.gov.au/resources/information-and-data/expenditure-data" |> 
  read_html() |>
  html_elements('div [href$="xlsx"]') |>
  html_attr("href") |> 
  as_tibble_col("url") |>
  # filter for venue urls
  filter(str_detect(url, "venue")) |> 
  # Add stub to urls
  mutate(
    url = str_c("https://www.vgccc.vic.gov.au//",url)) |> 
  # Create temp download file for each (hence rowwise)
  rowwise() |> 
  mutate( 
   download = tempfile(fileext = "xlsx")) |>
  ungroup() |> 
  # Download to temp file
  mutate(x =
    pmap(
    list(url,download),
    function(a,b) if(!file.exists(b)) download.file(a,b,mode="wb"))
    )  |>
  select(-x) |>
  # Get sheet names and filter for Detail data sheet
  mutate(sheet=map(download,readxl::excel_sheets)) |>
  unnest(sheet) |>
  filter(str_detect(sheet,"Detail")) |>
  # Read and unnest data
  mutate(
    data=pmap(list(download,sheet), readxl::read_excel, skip = 7, col_types = "text")) |> 
  unnest(data) |>
  # Make long
  pivot_longer(cols = c(contains("Exp"), contains("EGM"))) |> 
  # Fix names
  rename("venue_name" = Name) |> 
  janitor::clean_names() |> 
  # Filter for end of financial year data
  filter(!is.na(value), !str_detect(name,"Jan|Dec"),!is.na(venue_name)) |>
  # Identify and clean data
  mutate(measure_type = str_extract(name,"Expenditure|EGM"),
         venue_type = coalesce(venue_type,ven_type),
         financial_year = str_extract(sheet,"[0-9]{4} - [0-9]{4}") |> str_remove_all("\\s"),
         fy_date = fy::fy2date(financial_year),
         financial_year = fy::date2fy(fy_date),
         value = as.numeric(value)) |> 
  select(-name) |> 
  # Remove data where expernditure and machines are zero in the year
  group_by(venue_name, lga_name, financial_year) |> 
  filter(!sum(value)==0) |> 
  ungroup() |> 
  # Clean venue and lga names
  mutate(
         lga_name = lgvdatR::clean_lga(lga_name),
         venue_name = clean_egm(venue_name)
         ) |> 
  
  # Combine venue data where venue name changed mid-year and both reported
  # eg Milanos/Brighton BEach Hotel
  group_by(venue_name, lga_name, financial_year, measure_type) |> 
  # We can use sum for both measure_types as EGM == 0 for at least one report.
  mutate(value = sum(value)) |> 
  ungroup() |> 
  # Keep only one row
  unique() |> 
  select(-url:-sheet,-ven_type) |> 
 
  # Add missing EGM values, noting we only have rows with Expenditure so EGM value can't be zero
  arrange(fy_date) |> 
  mutate(
    value = if_else(measure_type=="EGM"&value==0,NA_real_,value)
  ) |> 
  group_by(venue_name, lga_name, measure_type) |> 
  fill(value) |> 
  ungroup()
  


# Read and clean location data saved locally. 
# This data is sourced from https://geomaps.vgccc.vic.gov.au/ and missing data added manually
location.data =
  read_csv("./data-raw/egm_locations.csv") |> 
  janitor::clean_names() |> 
  mutate(venue_name = clean_egm(venue_name),
         lga_name =  lgvdatR::clean_lga(lga)) |> 
  select(venue_name, lga_name, lat, long)

# Add locations to venue data
egm_venue_data = 
  egm_venue_data |> 
  left_join(
    location.data,
    by = join_by(lga_name, venue_name))

# Test for missing locations
missing = egm_venue_data |>
  filter(is.na(lat)) 

usethis::use_data(egm_venue_data, overwrite = TRUE)
usethis::use_r("data_doc.R")
gh auth login
