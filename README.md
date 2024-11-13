
<!-- README.md is generated from README.Rmd. Please edit that file -->

# vcglR

The goal of vcglR is to make Victorian gambling data available in tidy
format.

## Installation

You can install the development version of vcglR like so:

``` r
# install.packages("devtools")
devtools::install_github("zerogetsamgow/dohactheme")
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
format.

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
