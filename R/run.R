#' run
#'
#' This function is only meant to be run by piktests::runInRenv. Runs all integration tests in a mostly isolated runtime
#' environment.
#'
#' A runtimeWorkingDirectory is created and used as the working directory while running the tests, also a
#' madratCacheFolder and a madratOutputFolder are created and used while running the tests.
#'
#' @param useSbatch Whether to start the tests via sbatch (run in background) or directly in the current shell.
#' @param madratConfig The madrat configuration to use.
#'
#' @importFrom madrat setConfig
#' @importFrom withr local_options
run <- function(useSbatch, madratConfig) {
  cacheFolder <- file.path(getwd(), "madratCacheFolder")
  dir.create(cacheFolder)
  outputFolder <- file.path(getwd(), "madratOutputFolder")
  dir.create(outputFolder)
  dir.create("preprocessings")

  local_options(madrat_cfg = madratConfig)
  setConfig(cachefolder = cacheFolder, outputfolder = outputFolder, .local = TRUE)
  madratConfig <- getOption("madrat_cfg")
  saveRDS(madratConfig, "madratConfig.rds")

  # TODO remove rgdal dependency in DESCRIPTION once rgdal is a dependency of mrmagpie
  runPreprocessing(madratConfig, "mrmagpie", list("cellularmagpie", rev = 4.63), useSbatch)
  runPreprocessing(madratConfig, "mrremind", list("remind"), useSbatch)
}
