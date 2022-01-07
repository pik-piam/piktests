#' run
#'
#' Runs integration tests in an isolated runtime environment.
#'
#' A madratCacheFolder and a madratOutputFolder are created and used while running the tests. The non-public magpie
#' preprocessing repo `git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git` is cloned, so you need access to it.
#'
#' @param renvInstallPackages After installing other packages, renv::install(renvInstallPackages) is called.
#' Use this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' @param piktestsFolder A new folder for this piktests run is created in the given directory.
#' @param whatToRun A character vector defining what tests to run. See default value for a list of all possible tests.
#' @param runFolder In general this should be left as default. Where the folder for this piktests run should be created.
#' @param runInNewRSession Exists for testing. A function like `callr::r` taking a function and arguments to execute
#' in a new R session.
#' @return Invisibly, the path to the folder holding everything related to this piktests run.
#'
#' @author Pascal Führlich
#'
#' @importFrom callr r
#' @importFrom madrat setConfig
#' @export
run <- function(renvInstallPackages = NULL,
                piktestsFolder = getwd(),
                whatToRun = c("remind-preprocessing", "magpie-preprocessing"),
                runFolder = file.path(piktestsFolder, format(Sys.time(), "%Y_%m_%d-%H_%M")),
                runInNewRSession = callr::r) {
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder, recursive = TRUE)
  runFolder <- normalizePath(runFolder)
  cacheFolder <- file.path(runFolder, "madratCacheFolder")
  dir.create(cacheFolder)
  outputFolder <- file.path(runFolder, "madratOutputFolder")
  dir.create(outputFolder)

  gitCloneRepos <- "git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git"
  names(gitCloneRepos) <- file.path(runFolder, "preprocessings", "magpie")
  runInNewRSession(setupRenv, list(runFolder, gitCloneRepos, renvInstallPackages), show = TRUE, spinner = FALSE)

  setConfig(cachefolder = cacheFolder, outputfolder = outputFolder, .local = TRUE)
  madratConfig <- getOption("madrat_cfg")
  saveRDS(madratConfig, file.path(runFolder, "madratConfig.rds"))

  # not used further, just for archiving/looking up later
  saveRDS(list(options = options(), # nolint
               environmentVariables = Sys.getenv(),
               locale = Sys.getlocale()),
          file.path(runFolder, "optionsEnvironmentVariablesLocale.rds"))

  if ("magpie-preprocessing" %in% whatToRun) {
    runLongJob(function() source(file.path("start", "default.R")), # nolint
               workingDirectory = file.path(runFolder, "preprocessings", "magpie"),
               renvToLoad = runFolder,
               madratConfig = madratConfig,
               jobName = paste0("piktests-magpie-preprocessing_", substring(tempfile("", ""), 2)))
  }

  if ("remind-preprocessing" %in% whatToRun) {
    runLongJob(function() {
                 # sidestep package check warning (mrremind not in DESCRIPTION); ok because setupRenv installs mrremind
                 library(paste0("mr", "remind"), character.only = TRUE) # nolint
                 madrat::retrieveData("remind", cachetype = "def")
               },
               workingDirectory = file.path(runFolder, "preprocessings", "remind"),
               renvToLoad = runFolder,
               madratConfig = madratConfig,
               jobName = paste0("piktests-remind-preprocessing_", substring(tempfile("", ""), 2)))
  }

  return(invisible(runFolder))
}
