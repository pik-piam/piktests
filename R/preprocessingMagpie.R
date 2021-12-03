#' @importFrom gert git_clone
#' @importFrom withr local_dir local_options
preprocessingMagpie <- function(madratConfig, useSbatch, runFolder) {
  workFunction <- function(madratConfig) {
    withr::local_options(madrat_cfg = madratConfig, nwarnings = 10000, error = function() {
      traceback(2, max.lines = 1000)
      if (!interactive()) {
        quit(save = "no", status = 1, runLast = TRUE)
      }
    })
    withr::local_dir("preprocessing-magpie")
    source(file.path("start", "default.R")) # nolint
    warnings()
  }
  runInNewRSession(workFunction, arguments = list(madratConfig = madratConfig), renvProject = runFolder,
                   workFilePath = file.path(runFolder, "preprocessings", "magpie_work.rds"), useSbatch = useSbatch,
                   sbatchArguments = c("--job-name=piktests-magpie-preprocessing",
                                       "--output=magpie-preprocessing.log",
                                       "--mail-type=END",
                                       "--qos=priority",
                                       "--mem=50000"))
}
