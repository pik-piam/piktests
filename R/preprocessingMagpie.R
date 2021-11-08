#' @importFrom gert git_clone
#' @importFrom withr local_dir local_options
preprocessingMagpie <- function(madratConfig, useSbatch) {
  # TODO remove rgdal dependency in DESCRIPTION once rgdal is a dependency of mrmagpie
  git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git", path = "preprocessing-magpie")
  workFunction <- function(madratConfig) {
    withr::local_options(madrat_cfg = madratConfig, nwarnings = 10000, error = function() {
      traceback(2, max.lines = 1000)
      if (!interactive())
        quit(save = "no", status = 1, runLast = TRUE)
    })
    withr::local_dir("preprocessing-magpie")
    source(file.path("start", "default.R")) # nolint
    warnings()
  }
  runInNewRSession(workFunction, arguments = list(madratConfig = madratConfig), useSbatch = useSbatch)
}
