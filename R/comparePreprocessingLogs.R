#' comparePreprocessingLogs
#'
#' Convenience function for comparing logs after running `piktests::runWithComparison`.
#'
#' @param preprocessingName Name of the preprocessing you want to compare logs for, e.g. "magpie" or "remind".
#' @param runFolder The path to a run folder created by `piktests::runWithComparison`.
#'
#' @author Pascal Führlich
#' @seealso \code{\link{runWithComparison}}
#'
#' @export
comparePreprocessingLogs <- function(preprocessingName, runFolder = getwd()) {
  logPaths <- Sys.glob(file.path(runFolder, c("old", "new"), "preprocessings", preprocessingName,
                                 paste0("piktests-", preprocessingName, "-preprocessing_*.log")))
  compareLogs(logPaths[[1]], logPaths[[2]])
}
