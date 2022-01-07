#' comparePreprocessingLogs
#'
#' Convenience function for comparing logs after running `piktests::runWithComparison`.
#'
#' @param preprocessingName "magpie" or "remind"
#' @param runFolder The path to a run folder created by `piktests::runWithComparison`.
#'
#' @author Pascal Führlich
#' @seealso \code{\link{runWithComparison}}
#'
#' @export
comparePreprocessingLogs <- function(preprocessingName, runFolder = getwd()) {
  preprocessingName <- match.arg(preprocessingName, c("magpie", "remind"))
  logPaths <- file.path(runFolder, c("old", "new"), "preprocessings", preprocessingName,
                        paste0("piktests-", preprocessingName, "-preprocessing.log"))
  compareLogs(logPaths[[1]], logPaths[[2]])
}
