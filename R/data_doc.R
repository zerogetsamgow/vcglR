#' @title Victorian gaming venue data
#' @description Tidy data set of Victorian gaming machine data by venue and year
#' @format A data frame with `r nrow(egm_venue_data)` rows and `r ncol(egm_venue_data)` variables:
#' \describe{
#'   \item{\code{venue_name}}{The name of the venue, cleaned with clean_egm}
#'   \item{\code{venue_type}}{The type of venue, either 'Club' or 'Hotel'}
#'   \item{\code{lga_name}}{The name of the local government area the venue is in.}
#'   \item{\code{financial_year}}{The financial year of the data, as a character variable.}
#'   \item{\code{fy_date}}{The financial year of the data, as a Date variable.}
#'   \item{\code{measure_type}}{The type of data stored in value, either 'EGM' being the number of Machines or 'Expenditure' being player loss}
#'   \item{\code{value}}{A numeric being the amount of measure_type for that venue and financial_year}
#'   \item{\code{lat}}{The latitude of the venue}
#'   \item{\code{long}}{The longitude of the venue}
#'   
#'}
#' @source \url{https://www.vgccc.vic.gov.au/resources/information-and-data/expenditure-data}
"egm_venue_data"