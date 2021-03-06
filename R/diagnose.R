

#' diagnose
#'
#' this function is reproduced from the excellent `dlookr` package with a few tweaks
#' because I consider it an essential validation function, but the `dlookr` package itself has
#' some dependencies which can be problematic for some machines to download.
#'
#' @param df dataframe
#' @param ... tidyselect
#'
#' @return dataframe summary
#' @export
#'
#' @examples iris %>% diagnose()
diagnose <- function(df, ...) {

  df <- select_otherwise(df, ..., otherwise = tidyselect::everything(), return_type = "df")

  vars <- names(df)

  variable_type <- purrr::map_chr(df, ~class(.)[1])

  missing_count <- purrr::map_int(df, count_missing)

  unique_count <- purrr::map_int(df, dplyr::n_distinct)

  data_count <- nrow(df)

  if(data_count == 0){

    return(print("data frame is empty") )
  }

  tibble::tibble(variables = vars, types = variable_type,
         missing_count = missing_count,
         missing_percent = missing_count / data_count * 100,
         unique_count = unique_count,
         unique_rate = unique_count / data_count)
}


count_missing <- function(x){

  sum(is.na(x))
}

#' diagnose_missing
#'
#' @param df dataframe
#' @param ... optional tidyselect
#'
#' @return tibble summary
#' @export
diagnose_missing <- function(df, ...){

  missings <- NULL

  df <- select_otherwise(df,
                     ...,
                     otherwise = tidyselect::everything(),
                     return_type = "df")

  missing_count <-  purrr::map_df(df, count_missing)

  missing_count %>%
    t() %>%
    as.data.frame() %>%
    tibble::rownames_to_column() %>%
    tibble::as_tibble() %>%
    rlang::set_names(c("column", "missings")) %>%
    dplyr::arrange(dplyr::desc(missings )) %>%
    dplyr::filter(missings > 0) -> missing_count

  missing_count %>%
    unlist() %>%
    rlang::is_empty() -> misscond

if(misscond){
  print("no missings")} else{
    missing_count
  }
}

#' view_missing
#'
#' View rows of the dataframe where columns in the tidyselect specification contain missings
#' by default, detects missings in any column. The result is by default displayed in the viewer pane.
#' Can be returned as a tibble optionally.
#'
#' @param df dataframe
#' @param ... tidyselect
#' @param view logical. if false, returns tibble
#'
#' @return tibble
#' @export
view_missing <- function(df, ..., view = T){

  df %>% select_otherwise(..., otherwise = tidyselect::everything()) -> col_indx

  df %>%
    dplyr::filter(dplyr::if_any(tidyselect::any_of(col_indx), .fns = is.na)) -> missings

  if(view){
    utils::View(missings)
  } else{
    missings
  }
}



#' diagnose category
#'
#' @param .data dataframe
#' @param max_distinct integer
#'
#' @return dataframe
#' @export
diagnose_category <- function(.data, ..., max_distinct = 5){
  n <-  NULL

  .data %>%
    purrr::map_int(dplyr::n_distinct) %>%
    subset(. < max_distinct) %>%
    names() -> nms

  .data %>%
    select_otherwise(..., otherwise = where(is.character) | where(is.factor),　return_type = "names") -> nms1

  intersect(nms, nms1) -> nms2

  purrr::map(nms2,
             function(x) {.data %>%
                 dplyr::count(!!rlang::sym(x)) %>%
                 dplyr::mutate(column = names(.)[1], .before = 1) %>%
                 dplyr::rename(level = 2) %>%
                 dplyr::arrange(desc(n))}) %>%
    rlist::list.rbind() %>%
    tibble::as_tibble()
}
