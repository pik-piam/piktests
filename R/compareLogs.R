#' compareLogs
#'
#' Show side-by-side diff of the two given log files.
#'
#' Runtimes are removed from logs before comparison.
#'
#' @param pathToLogA Path to the first log file, shown on the left hand side in the resulting diff.
#' @param pathToLogB Path to the second log file, shown on the right hand side in the resulting diff.
#'
#' @importFrom withr local_tempfile
#' @export
compareLogs <- function(pathToLogA, pathToLogB) {
  if (!requireNamespace("diffr", quietly = TRUE)) {
    stop("compareLogs requires diffr. Please run: install.packages('diffr')")
  }
  cleanLog <- function(pathToLog, pathToCleanedLog) {
    stopifnot(is.character(pathToLog) && length(pathToLog) == 1)
    logContent <- readLines(pathToLog)
    cleanedContent <- gsub('(in [0-9.]+ (seconds|Minutes")$|-F[^.]+\\.rds$)', "", logContent)
    writeLines(cleanedContent, pathToCleanedLog)
  }

  pathToCleanedLogA <- local_tempfile()
  cleanLog(pathToLogA, pathToCleanedLogA)

  pathToCleanedLogB <- local_tempfile()
  cleanLog(pathToLogB, pathToCleanedLogB)

  diffr::diffr(pathToCleanedLogA, pathToCleanedLogB)
}
