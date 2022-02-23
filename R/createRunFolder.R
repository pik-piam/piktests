#' createRunFolder
#'
#' Constructs a folder name based on current data and existing folders
#'
#' @param computationNames A subset of names(piktests::computations). The setup and compute functions of these
#' computations are executed.
#' @param piktestsFolder A new folder for this piktests run is created in the given directory.
#' @param runFolder Path where a folder for this piktests run should be created. Generally should be left as default,
#' which creates a folder name based on the current date, time, and computationNames.
#' @author Jan Philipp Dietrich
createRunFolder <- function(computationNames = c("magpiePrep", "remindPrep"), piktestsFolder = getwd(),
                            runFolder = NULL) {
  if (is.null(runFolder)) {
    now <- format(Sys.time(), "%y%b%d")
    for (l in c("", letters)) {
      runFolder <- file.path(piktestsFolder, paste0(now, l, "_", paste(computationNames, collapse = "_")))
      if (!file.exists(runFolder)) break
    }
  }
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder, recursive = TRUE)
  return(normalizePath(runFolder))
}
