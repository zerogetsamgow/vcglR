## code to prepare `egm_venue_data` 

egm_venue_data = 
  # Get html from following url and extract hrefs for xlsx files
  "https://www.vgccc.vic.gov.au/resources/information-and-data/expenditure-data" |> 
  rvest::read_html() |>
  rvest::html_elements('div [href$="xlsx"]') |>
  rvest::html_attr("href") |> 
  tibble::as_tibble_col("url") |>
  # filter for venue urls
  dplyr::filter(
    stringr::str_detect(url, "venue")) |> 
  # Add stub to urls
  dplyr::mutate(
    url = stringr::str_c("https://www.vgccc.vic.gov.au",url)) |> 
  # Create temp download file for each (hence rowwise)
  dplyr::rowwise() |> 
  dplyr::mutate( 
    download = tempfile(fileext = "xlsx")) |>
  dplyr::ungroup() |> 
  # Download to temp file
  dplyr::mutate(x =
    purrr::pmap(
    list(url,download),
    function(a,b) if(!file.exists(b)) download.file(a,b,mode="wb"))
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
      purrr::pmap(list(download,sheet), readxl::read_excel, skip = 7, col_types = "text")) |> 
  tidyr::unnest(data) |>
  # Make long
  tidyr::pivot_longer(cols = c(contains("Exp"), contains("EGM"))) |> 
  # Fix names
  dplyr::rename("venue_name" = Name) |> 
  janitor::clean_names() |> 
  # Filter for end of financial year data
  dplyr::filter(!is.na(value), !stringr::str_detect(name,"Jan|Dec"),!is.na(venue_name)) |>
  # Identify and clean data
  dplyr::mutate(
    measure_type = stringr::str_extract(name,"Expenditure|EGM"),
    measure_type = factor(measure_type, levels = c("EGM","Expenditure")),
         venue_type =
           dplyr::coalesce(venue_type,ven_type),
         financial_year = 
           stringr::str_extract(
             sheet,
             "[0-9]{4} - [0-9]{4}") |> 
           stringr::str_remove_all("\\s"),
         fy_date = fy::fy2date(financial_year),
         financial_year = fy::date2fy(fy_date),
         venue_type = factor(venue_type, levels = c("Club","Hotel")),
         
         value = as.numeric(value)) |> 
  dplyr::select(-name) |> 
  # Remove data where expernditure and machines are zero in the year
  dplyr::group_by(
    venue_name, 
    lga_name, 
    financial_year) |> 
  dplyr::filter(!sum(value)==0) |> 
  dplyr::ungroup() |> 
  # Clean venue and lga names
  dplyr::mutate(
    lga_name = vpstheme::clean_vic_lga(lga_name),
    venue_name = vcglR::clean_egm(venue_name)
    ) |> 
  # Combine venue data where venue name changed mid-year and both reported
  # eg Milanos/Brighton Beach Hotel
  dplyr::group_by(venue_name, lga_name, financial_year, measure_type) |> 
  # We can use sum for both measure_types as EGM == 0 for at least one report.
  dplyr::mutate(value = sum(value)) |> 
  dplyr::ungroup() |> 
  # Keep only one row
  unique() |> 
  dplyr::select(
    venue_name, 
    venue_type, 
    lga_name, financial_year, fy_date, measure_type, value) |> 
  # Add missing EGM values, noting we only have rows with Expenditure so EGM value can't be zero
  dplyr::arrange(fy_date) |> 
  dplyr::mutate(
    value = 
      dplyr::if_else(
        measure_type == "EGM" & value == 0,
        NA_real_,
        value)
  ) |> 
  dplyr::group_by(venue_name, lga_name, measure_type) |> 
  tidyr::fill(value) |> 
  tidyr::fill(venue_type) |> 
  dplyr::ungroup()
  


# Read and clean location data saved locally. 
# This data is sourced from https://geomaps.vgccc.vic.gov.au/ and missing data added manually
location.data =
  readr::read_csv("./data-raw/egm_locations.csv") |> 
  janitor::clean_names() |> 
  dplyr::mutate(
   venue_name = vcglR::clean_egm(venue_name),
   lga_name =  vpstheme::clean_vic_lga(lga)) |> 
  dplyr::select(
    venue_name, 
    lga_name, lat, long)

# Add locations to venue data
egm_venue_data = 
  egm_venue_data |> 
  dplyr::left_join(
    location.data,
    by = 
      dplyr::join_by(
        lga_name, 
        venue_name))

# Test for missing locations
missing = 
  egm_venue_data |>
  dplyr::filter(is.na(lat)) 

if(nrow(missing)>0) {warning("Some venues are missing location data")}

egm_venue_data =
  egm_venue_data |> 
  unique()
# Save data
usethis::use_data(egm_venue_data, overwrite = TRUE)
