## code to prepare `egm_lga_data` 

#library(tidyverse)
#library(rvest)

raw_egm_lga_data =   # Get html from following url and extract hrefs for xlsx files
  "https://www.vgccc.vic.gov.au/resources/information-and-data/expenditure-data" |> 
  rvest::read_html() |>
  rvest::html_elements('div [href$="xlsx"]') |>
  rvest::html_attr("href") |> 
  tibble::as_tibble_col("url") |>
  # filter for venue urls
  dplyr::filter(
    stringr::str_detect(
      stringr::str_to_lower(url), "monthly")) |> 
  # Add stub to urls
  dplyr::mutate(
    url = 
      stringr::str_c(
        "https://www.vgccc.vic.gov.au",
        url)) |> 
  # Create temp download file for each (hence rowwise)
  dplyr::rowwise() |> 
  dplyr::mutate( 
    download = tempfile(fileext = "xlsx")) |>
  dplyr::ungroup() |> 
  # Download to temp file
  dplyr::mutate(
    x =
      purrr::pmap(
        list(url,download),
        function(a,b) if(!file.exists(b)) download.file(a,b, mode = "wb"))
  )  |>
  dplyr::select(-x) |>
  # Get sheet names and filter for Detail data sheet
  dplyr::mutate(
    sheet = purrr::map(
      download,
      readxl::excel_sheets)) |>
  tidyr::unnest(sheet) |>
  dplyr::filter(
    stringr::str_detect(sheet,"Detail")) |>
  # Read and unnest data
  dplyr::mutate(
    data = 
      purrr::pmap(
        list(download,sheet), 
        readxl::read_excel, 
        skip = 9, 
        col_types = "text")) |> 
  tidyr::unnest(data)

# Get player_loss data
player_loss = raw_egm_lga_data |> 
  janitor::clean_names() |> 
  dplyr::select(
    url, 
    download, 
    sheet, 
    lga_name, 
    tidyselect::contains("player")) |> 
  tidyr::pivot_longer(
    tidyselect::contains("player")) |> 
  dplyr::filter(
    !is.na(lga_name),
    !str_detect(lga_name,"Published|Please")) |> 
  dplyr::mutate(
    lga_name = 
      vpstheme::clean_vic_lga(lga_name)) |> 
  dplyr::group_by(
    sheet, 
    lga_name) |> 
  dplyr::slice_head(n = 12) |> 
  dplyr::mutate(
    month = 12:1,
    financial_year = 
      stringr::str_extract(sheet,"[0-9]{4}-[0-9]{4}") |> fy::fy2date(),
    data_month = 
      lubridate::ceiling_date(
        lubridate::floor_date(financial_year, "months") - months(month-1),"months"),
    data_month = 
      data_month - 
      lubridate::days(1)) |> 
  dplyr::mutate(
    value = as.numeric(value),
    name = "Expenditure")

# Get venues data
venues = raw_egm_lga_data |> 
  janitor::clean_names() |> 
  dplyr::select(
    url, 
    download, 
    sheet, 
    lga_name, 
    tidyselect::contains("venue")) |> 
  tidyr::pivot_longer(
    tidyselect::contains("venue")) |> 
  dplyr::filter(
    !is.na(lga_name),
    !stringr::str_detect(lga_name,"Published|Please")) |> 
  dplyr::mutate(
    lga_name = 
      vpstheme::clean_vic_lga(lga_name)) |> 
  dplyr::group_by(
    sheet, 
    lga_name) |> 
  dplyr::slice_head(n = 12) |> 
  dplyr::mutate(
    month = 12:1,
    financial_year = str_extract(sheet,"[0-9]{4}-[0-9]{4}") |> fy::fy2date(),
    data_month =
      lubridate::ceiling_date(
        lubridate::floor_date(financial_year, "months") - months(month-1),"months"),
    data_month = data_month - days(1)) |> 
  dplyr::mutate(
    value = as.numeric(value),
    name = "Venues")

# Get machines data
machines = raw_egm_lga_data |> 
  janitor::clean_names() |> 
  dplyr::select(
    url, 
    download, 
    sheet, 
    lga_name, 
    tidyselect::contains("eg_")) |> 
  tidyr::pivot_longer(contains("eg")) |> 
  dplyr::filter(
    !is.na(lga_name),
    !stringr::str_detect(
      lga_name,"Published|Please")) |> 
  dplyr::mutate(
    lga_name = 
      vpstheme::clean_vic_lga(lga_name)) |> 
  dplyr::group_by(
    sheet, 
    lga_name) |> 
  dplyr::slice_head(n=12) |> 
  dplyr::mutate(
    month = 12:1,
    financial_year = 
      stringr::str_extract(sheet,"[0-9]{4}-[0-9]{4}") |>
      fy::fy2date(),
    data_month = 
      lubridate::ceiling_date(
        lubridate::floor_date(financial_year, "months") - months(month-1),"months"),
    data_month = data_month - days(1)) |> 
  dplyr::mutate(
    value = as.numeric(value),
    name = "EGMs")

# Gather new data
new_lga_data = 
  dplyr::bind_rows(
    player_loss,
    machines,
    venues) |> 
  dplyr::ungroup() |> 
  dplyr::select(lga_name, financial_year, data_month, "measure_type" = name, value) |> 
  dplyr::filter_out(
    is.na(value)
  )

# Add new data to old data - step added as VGCCC removes sheets of data from time to time
egm_lga_data =
  dplyr:: bind_rows(
    vcglR::egm_lga_data,
    new_lga_data
  ) |> 
  unique() |> 
  dplyr::filter_out(
    is.na(value)
  )


# Save data
usethis::use_data(egm_lga_data, overwrite = TRUE)


