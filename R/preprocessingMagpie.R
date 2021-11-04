#' @importFrom gert git_clone
#' @importFrom withr local_dir
preprocessingMagpie <- function(madratConfig, useSbatch) {
  # TODO remove rgdal dependency in DESCRIPTION once rgdal is a dependency of mrmagpie
  git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git", path = "preprocessing-magpie")
  local_dir("preprocessing-magpie")
  workFunction <- function(madratConfig) {
    withr::local_options(madrat_cfg = madratConfig, nwarnings = 10000)
    source(file.path("start", "default.R")) # nolint
    warnings()
  }
  runInNewRSession(workFunction, arguments = list(madratConfig = madratConfig), useSbatch = useSbatch)
}
