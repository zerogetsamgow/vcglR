
<!-- README.md is generated from README.Rmd. Please edit that file -->

# vcglR

The goal of vcglR is to make Victorian gambling data available in tidy
format.

## Installation

You can install the development version of vcglR like so:

``` r
# install.packages("devtools")
devtools::install_github("zerogetsamgow/vcglR")
```

## Gaming venue data

The Victorian gambling regulator publishes gaming machine data by venue
[on its
website.](https://www.vgccc.vic.gov.au/resources/information-and-data/expenditure-data)

Released twice a year, this dataset includes gaming expenditure at each
gaming venue, and the number of gaming machines it has.

The data is published as `.xlsx` data. Historical data is also
available.

The `vcglr` package reads this data, cleans it and converts it tidy
format. Data is stored as `egm_venue_data.rda` allowing it to be loaded
with:

``` r
egm_data = vcglR::egm_venue_data

dplyr::glimpse(egm_data)
#> Rows: 16,561
#> Columns: 9
#> $ venue_name     <chr> "Geelong Football Club", "Geelong Football Club", "Red …
#> $ venue_type     <fct> Club, Club, Club, Club, Club, Club, Club, Club, Club, C…
#> $ lga_name       <chr> "Greater Geelong", "Greater Geelong", "Mildura", "Mildu…
#> $ financial_year <fy> 2008-09, 2008-09, 2008-09, 2008-09, 2008-09, 2008-09, 20…
#> $ fy_date        <date> 2009-06-30, 2009-06-30, 2009-06-30, 2009-06-30, 2009-0…
#> $ measure_type   <fct> Expenditure, EGM, Expenditure, EGM, Expenditure, EGM, E…
#> $ value          <dbl> 4416532.9, 100.0, 2206156.3, 34.0, 3336511.8, 83.0, 577…
#> $ lat            <dbl> -38.15760, -38.15760, -34.30460, -34.30460, -37.93730, …
#> $ long           <dbl> 144.3531, 144.3531, 142.1877, 142.1877, 145.0431, 145.0…
```

Cleaning consists of:

- updating and standardising venue names `venue_name` to the latest
  known venue name

- standardising local government areas `lga_name` to an abbreviated
  format.

- gathering quantitative data (the number of gaming machines and player
  loss) to long format and replacing missing data (0 counts of gaming
  machines). The type of data is denoted by `measure_type`, values are
  stored as `value`.

- removing half-year data - only full financial year data is retained

- cleaning the date information for each financial year and saving it as
  a character variable `financial_year` and date `fy_date` variable.

The package also adds geo-location data for each venue in the dataset.
Location data was initially sourced from the regulator’s [mapping
tool](https://geomaps.vgccc.vic.gov.au/). Missing data was added
manually and saved in `egm_locatons.csv` in `/data-raw/`

## Monthly LGA data

The Victorian gambling regulator publishes gaming machine data by LGA
[on its
website.](https://www.vgccc.vic.gov.au/resources/information-and-data/expenditure-data)

Released monthly, this dataset includes gaming expenditure for each LGA,
and the number of gaming machines and venues operating in the LGA.

The data is published as `.xlsx` data. Historical data is also
available.

The `vcglR` package reads this data, cleans it and converts it tidy
format. Data is stored as `egm_lga_data.rda` allowing it to be loaded
with:

``` r
lga_data = vcglR::egm_lga_data

dplyr::glimpse(lga_data)
#> Rows: 8,208
#> Columns: 5
#> $ lga_name       <chr> "Alpine", "Alpine", "Alpine", "Alpine", "Alpine", "Alpi…
#> $ financial_year <date> 2019-06-30, 2019-06-30, 2019-06-30, 2019-06-30, 2019-0…
#> $ data_month     <date> 2018-08-01, 2018-09-01, 2018-10-01, 2018-11-01, 2018-1…
#> $ measure_type   <chr> "Expenditure", "Expenditure", "Expenditure", "Expenditu…
#> $ value          <dbl> 224281.3, 156538.2, 202779.0, 173965.4, 179321.2, 18943…
```

Cleaning consists of:

- standardising local government areas `lga_name` to an abbreviated
  format.

- gathering quantitative data (the number of gaming machines and player
  loss) to long format. The type of data is denoted by `measure_type`,
  values are stored as `value`.

- cleaning the date information for each financial year and saving it as
  a date variable `financial_year` and month of data `data_month`
  variable.
