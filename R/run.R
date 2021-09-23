#' run
#'
#' Runs all integration tests available in a mostly isolated runtime environment.
#'
#' A new folder will be created for each run, named after the current date/time. In this folder a madratCacheFolder and
#' a madratOutputFolder are created and used while running the tests. A runtimeWorkingDirectory is also created and
#' while running the tests this will be the working directory. The original madrat configuration and working directory
#' will be restored afterwards.
#'
#' @param path Path to a folder. Here, a new folder named after the current date/time will be created for this test run.
#' @importFrom madrat setConfig
#' @importFrom withr local_dir
#' @export
run <- function(path = ".") {
  stopifnot(length(path) == 1)
  testRunFolder <- file.path(path, format(Sys.time(), "%Y_%m_%d-%H_%M"))
  stopifnot(!file.exists(testRunFolder))
  dir.create(testRunFolder)

  cacheFolder <- file.path(testRunFolder, "madratCacheFolder")
  dir.create(cacheFolder)
  setConfig(cachefolder = cacheFolder, .local = TRUE)

  outputFolder <- file.path(testRunFolder, "madratOutputFolder")
  dir.create(outputFolder)
  setConfig(outputfolder = outputFolder, .local = TRUE)

  # create renv

  runtimeWorkingDirectory <- file.path(testRunFolder, "runtimeWorkingDirectory")
  dir.create(runtimeWorkingDirectory)
  local_dir(runtimeWorkingDirectory)

  preprocessingMrremind()

  message("SUCCESS")
}
