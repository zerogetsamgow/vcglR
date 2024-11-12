## code to prepare `egm_dict` dataset goes here
#' Convert Victorian local government names into a consistent format
#'
#' @param x a (character) vector containing Australian state names or abbreviations or
#' a (numeric) vector containing state codes (1 = NSW, 2 = Vic, 3 = Qld, 4 = SA,
#' 5 = WA, 6 = Tas, 7 = NT, 8 = ACT).
#'
#' @param to what form should the state names be converted to? Options are
#' "egm_name", "venue_abbr" (the default), "egm_abs", and "egm_code".
#'
#' @param fuzzy_match logical; either TRUE (the default) which indicates that
#' approximate/fuzzy string matching should be used, or FALSE which indicates that
#' only exact matches should be used.
#'
#' @param max_dist numeric, sets the maximum acceptable distance between your
#' string and the matched string. Default is 0.4. Only relevant when fuzzy_match is TRUE.
#'
#' @param method the method used for approximate/fuzzy string matching. Default
#' is "jw", the Jaro-Winker distance; see `??stringdist-metrics` for more options.
#'#'
#' @return a character vector of state names, abbreviations, or codes.
#'
#' @rdname clean_lga
#' @examples
#'
#' library(lgvdatR)
#'
#' x <- c("Melburn", "Wang", "Donga")
#'
#' # Convert the above to state abbreviations
#' clean_lga(x)
#'
#' # Convert the elements of `x` to state names
#'
#' clean_lga(x, to = "name")
#'
#' # Disable fuzzy matching; you'll get NAs unless exact matches can be found
#'
#' clean_lga(x, fuzzy_match = FALSE)
#'
#' # You can use clean_lga in a dplyr mutate call
#'
#' x_df <- data.frame(lga = x, stringsAsFactors = FALSE)
#'
#' \dontrun{x_df |> mutate(venue_abbr = clean_lga(lga))}
#'
#' @importFrom stringdist amatch
#' @export

clean_egm <- function(x, to = "venue_abbr", fuzzy_match = TRUE, max_dist = 0.4, method = "jw"){
  
  
  if(!is.logical(fuzzy_match)){
    stop("`fuzzy_match` argument must be either `TRUE` or `FALSE`")
  }
  
  if(!is.numeric(x)) {
    x <- egm_string_tidy(x)
  }
  
  if(fuzzy_match){
    matched_abbr <- names(egm_dict[stringdist::amatch(x, tolower(egm_dict),
                                                      method = method,
                                                      matchNA = FALSE,
                                                      maxDist = max_dist)])
  } else {
    matched_abbr <- names(egm_dict[match(x, tolower(egm_dict))])
  }
  
  ret <- egm_table[[to]][match(matched_abbr, egm_table$venue_abbr)]
  
  ret <- as.character(ret)
  
  ret
  
}




egm_string_tidy <- function(string){
  
  string <- stringr::str_to_lower(string)
  
  string <- stringr::str_trim(string, "both")
  
  string <- ifelse(string %in% c("na", "n.a", "n.a.", "n a",
                                 "not applicable"),
                   NA_character_,
                   string)
  
  string
}

