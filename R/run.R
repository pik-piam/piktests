#' run
#'
#' Runs integration tests in an isolated runtime environment.
#'
#' A madratCacheFolder and a madratOutputFolder are created and used while running the tests.
#'
#' @param renvInstallPackages After installing other packages, renv::install(renvInstallPackages) is called.
#' Use this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' @param piktestsFolder A new folder for this piktests run is created in the given directory.
#' @param whatToRun A character vector defining what tests to run. See default value for a list of all possible tests.
#' @return Invisibly, the path to the folder holding everything related to this piktests run.
#'
#' @importFrom callr r
#' @importFrom gert git_clone
#' @importFrom madrat setConfig
#' @importFrom slurmR Slurm_EvalQ
#' @importFrom withr with_dir
run <- function(renvInstallPackages = NULL,
                piktestsFolder = getwd(),
                whatToRun = c("remind-preprocessing", "magpie-preprocessing")) {
  runFolder <- file.path(piktestsFolder, format(Sys.time(), "%Y_%m_%d-%H_%M"))
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder)
  cacheFolder <- file.path(runFolder, "madratCacheFolder")
  dir.create(cacheFolder)

  outputFolder <- file.path(runFolder, "madratOutputFolder")
  dir.create(outputFolder)

  # clone before setupRenv so renv can auto-detect dependencies
  git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git",
            path = file.path(runFolder, "preprocessings", "magpie"))
  callr::r(setupRenv, list(runFolder, renvInstallPackages))

  setConfig(cachefolder = cacheFolder, outputfolder = outputFolder, diagnostics = "madratDiagnostics", .local = TRUE)
  madratConfig <- getOption("madrat_cfg")
  saveRDS(madratConfig, file.path(runFolder, "madratConfig.rds"))

  # not used further, just for archiving/looking up later
  saveRDS(list(options = options(), # nolint
               environmentVariables = Sys.getenv(),
               locale = Sys.getlocale()),
          file.path(runFolder, "optionsEnvironmentVariablesLocale.rds"))

  if (isTRUE(grepl("magpie-preprocessing", whatToRun))) {
    runLongJob(function() source(file.path("start", "default.R")), # nolint
               workingDirectory = file.path(runFolder, "preprocessings", "magpie"),
               renvToLoad = runFolder,
               madratConfig = madratConfig,
               jobName = "piktests-magpie-preprocessing")
  }

  if (isTRUE(grepl("remind-preprocessing", whatToRun))) {
    runLongJob(function() {
                 # sidestep package check warning (mrremind not in DESCRIPTION); ok because setupRenv installs mrremind
                 library(paste0("mr", "remind"), character.only = TRUE) # nolint
                 madrat::retrieveData("remind", cachetype = "def")
               },
               workingDirectory = file.path(runFolder, "preprocessings", "remind"),
               renvToLoad = runFolder,
               madratConfig = madratConfig,
               jobName = "piktests-remind-preprocessing")
  }

  return(invisible(runFolder))
}
