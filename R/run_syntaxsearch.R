#' Executa o aplicativo Shiny
#'
#'
#' @import shiny
#' @import DT
#' @import wordcloud2
#' @import stringr
#' @import stringi
#' @import dplyr
#' @import tm
#' @export
#'
run_syntaxsearch <- function() {
  appDir <- system.file("app", package = "SyntaxSearch")
  shiny::runApp(appDir, display.mode = "normal")
}
