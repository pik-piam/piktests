#' run
#'
#' This function is only meant to be run by piktests::runInRenv. Runs all integration tests in a mostly isolated runtime
#' environment.
#'
#' A runtimeWorkingDirectory is created and used as the working directory while running the tests, also a
#' madratCacheFolder and a madratOutputFolder are created and used while running the tests.
#'
#' @param madratConfig The madrat configuration to use.
#'
#' @importFrom madrat setConfig
#' @importFrom withr local_options
run <- function(madratConfig = readRDS("initialMadratConfig.rds")) {
  cacheFolder <- file.path(getwd(), "madratCacheFolder")
  dir.create(cacheFolder)
  outputFolder <- file.path(getwd(), "madratOutputFolder")
  dir.create(outputFolder)
  dir.create("preprocessingLogs")

  local_options(madrat_cfg = madratConfig)
  setConfig(cachefolder = cacheFolder, outputfolder = outputFolder, .local = TRUE)
  saveRDS(getOption("madrat_cfg"), "madratConfig.rds")

  runPreprocessing("mrmagpie", "'cellularmagpie', rev = 4.63")
  runPreprocessing("mrremind", "'remind'")
}