## code to prepare `egm_lga_data` 

library(tidyverse)
library(rvest)

raw_egm_lga_data =   # Get html from following url and extract hrefs for xlsx files
  "https://www.vgccc.vic.gov.au/resources/information-and-data/expenditure-data" |> 
  rvest::read_html() |>
  rvest::html_elements('div [href$="xlsx"]') |>
  rvest::html_attr("href") |> 
  tibble::as_tibble_col("url") |>
  # filter for venue urls
  filter(str_detect(url, "LGA")) |> 
  # Add stub to urls
  mutate(
    url = str_c("https://www.vgccc.vic.gov.au",url)) |> 
  # Create temp download file for each (hence rowwise)
  rowwise() |> 
  mutate( 
    download = tempfile(fileext = "xlsx")) |>
  ungroup() |> 
  # Download to temp file
  mutate(x =
           pmap(
             list(url,download),
             function(a,b) if(!file.exists(b)) download.file(a,b, mode = "wb"))
  )  |>
  select(-x) |>
  # Get sheet names and filter for Detail data sheet
  mutate(sheet=map(download,readxl::excel_sheets)) |>
  unnest(sheet) |>
  filter(str_detect(sheet,"Detail")) |>
  # Read and unnest data
  mutate(
    data=pmap(list(download,sheet), readxl::read_excel, skip = 9, col_types = "text")) |> 
  unnest(data)

# Get player_loss data
player_loss = raw_egm_lga_data |> 
  janitor::clean_names() |> 
  select(url, download, sheet, lga_name, contains("player")) |> 
  pivot_longer(contains("player")) |> 
  filter(!is.na(lga_name),!str_detect(lga_name,"Published|Please")) |> 
  mutate(lga_name = vpstheme::clean_vic_lga(lga_name)) |> 
  group_by(sheet, lga_name) |> 
  slice_head(n=12) |> 
  mutate(month = 12:1,
         financial_year = str_extract(sheet,"[0-9]{4}-[0-9]{4}") |> fy::fy2date(),
         data_month = ceiling_date(floor_date(financial_year, "months") - months(month-1),"months"),
         data_month = data_month - days(1)) |> 
  mutate(value = as.numeric(value),
         name = "Expenditure")

# Get venues data
venues = raw_egm_lga_data |> 
  janitor::clean_names() |> 
  select(url, download, sheet, lga_name, contains("venue")) |> 
  pivot_longer(contains("venue")) |> 
  filter(!is.na(lga_name),!str_detect(lga_name,"Published|Please")) |> 
  mutate(lga_name = vpstheme::clean_vic_lga(lga_name)) |> 
  group_by(sheet, lga_name) |> 
  slice_head(n=12) |> 
  mutate(month = 12:1,
         financial_year = str_extract(sheet,"[0-9]{4}-[0-9]{4}") |> fy::fy2date(),
         data_month = ceiling_date(floor_date(financial_year, "months") - months(month-1),"months"),
         data_month = data_month - days(1)) |> 
  mutate(value = as.numeric(value),
         name = "Venues")

# Get machines data
machines = raw_egm_lga_data |> 
  janitor::clean_names() |> 
  select(url, download, sheet, lga_name, contains("eg_")) |> 
  pivot_longer(contains("eg")) |> 
  filter(!is.na(lga_name),!str_detect(lga_name,"Published|Please")) |> 
  mutate(lga_name = vpstheme::clean_vic_lga(lga_name)) |> 
  group_by(sheet, lga_name) |> 
  slice_head(n=12) |> 
  mutate(month = 12:1,
         financial_year = str_extract(sheet,"[0-9]{4}-[0-9]{4}") |> fy::fy2date(),
         data_month = ceiling_date(floor_date(financial_year, "months") - months(month-1),"months"),
         data_month = data_month - days(1)) |> 
  mutate(value = as.numeric(value),
         name = "EGMs")

# Gather new data
new_lga_data = 
  bind_rows(
    player_loss,
    machines,
    venues) |> 
  ungroup() |> 
  select(lga_name, financial_year, data_month, "measure_type" = name, value) 

# Add new data to old data - step added as VGCCC removes sheets of data from time to time
egm_lga_data =
  bind_rows(
    vcglR::egm_lga_data |> drop_na(),
    new_lga_data
  ) |> 
  unique()


# Save data
usethis::use_data(egm_lga_data, overwrite = TRUE)


