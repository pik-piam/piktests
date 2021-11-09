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
#' @importFrom withr local_options with_dir
run <- function(useSbatch, madratConfig) {
  cacheFolder <- file.path(getwd(), "madratCacheFolder")
  dir.create(cacheFolder)
  outputFolder <- file.path(getwd(), "madratOutputFolder")
  dir.create(outputFolder)

  local_options(madrat_cfg = madratConfig)
  setConfig(cachefolder = cacheFolder, outputfolder = outputFolder, .local = TRUE)
  madratConfig <- getOption("madrat_cfg")
  saveRDS(madratConfig, "madratConfig.rds")

  # magpie preprocessing
  dir.create(file.path("preprocessings", "magpie"), recursive = TRUE)
  with_dir(file.path("preprocessings", "magpie"), {
    preprocessingMagpie(madratConfig, useSbatch)
  })

  # remind preprocessing
  # runPreprocessing(madratConfig, "mrremind", list("remind"), useSbatch) # TODO comment this in
}
