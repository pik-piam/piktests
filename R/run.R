#' run
#'
#' Runs integration tests in an isolated runtime environment.
#'
#' A madratCacheFolder and a madratOutputFolder are created and used while running the tests. The non-public magpie
#' preprocessing repo `git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git` is cloned, so you need access to it.
#'
#' @param renvInstallPackages After installing other packages, renv::install(renvInstallPackages) is called.
#' Use this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' @param computationNames A subset of names(piktests::computations). The setup and compute functions of these
#' computations are executed.
#' @param piktestsFolder A new folder for this piktests run is created in the given directory.
#' @param runFolder Path where a folder for this piktests run should be created. Generally should be left as default,
#' which creates a folder name based on the current date, time, and computationNames.
#' @param executionMode Determines how long running jobs are started. One of "slurm", "directly"
#' @return Invisibly, the path to the folder holding everything related to this piktests run.
#'
#' @author Pascal Führlich
#'
#' @seealso \code{\link{computations}}
#'
#' @importFrom callr r
#' @importFrom madrat getConfig setConfig
#' @importFrom slurmR slurm_available
#' @importFrom withr with_output_sink
#' @export
run <- function(renvInstallPackages = NULL,
                computationNames = c("magpiePreprocessing", "remindPreprocessing"),
                piktestsFolder = getwd(),
                runFolder = NULL,
                executionMode = c("slurm", "directly")) {
  if (is.null(runFolder)) {
    runFolder <- file.path(piktestsFolder, paste0(format(Sys.time(), "%Y_%m_%d-%H_%M"), "-",
                                                  paste(computationNames, collapse = "_")))
  }
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder, recursive = TRUE)
  runFolder <- normalizePath(runFolder)

  with_output_sink(file.path(runFolder, "piktestsSetup.log"), split = TRUE, code = {
    executionMode <- match.arg(executionMode)
    if (executionMode == "slurm" && !slurm_available()) {
      warning("slurm is unavailable, falling back to direct execution (callr::r)")
      executionMode <- "directly"
    }

    r(setupRenv, list(runFolder, computationNames, renvInstallPackages), spinner = FALSE,
      show = !requireNamespace("testthat", quietly = TRUE) || !testthat::is_testing())

    madratMainFolder <- file.path(runFolder, "madratMainFolder")
    dir.create(madratMainFolder)
    setConfig(sourcefolder = getConfig("sourcefolder"),
              mappingfolder = getConfig("mappingfolder"),
              mainfolder = madratMainFolder,
              .local = TRUE)
    madratConfig <- getOption("madrat_cfg")
    saveRDS(madratConfig, file.path(runFolder, "madratConfig.rds"))

    # not used further, just for archiving/looking up later
    saveRDS(list(options = options(), # nolint
                 environmentVariables = Sys.getenv(),
                 locale = Sys.getlocale()),
            file.path(runFolder, "optionsEnvironmentVariablesLocale.rds"))
  })

  for (computationName in computationNames) {
    runLongJob(computations[[computationName]][["compute"]],
               workingDirectory = file.path(runFolder, "computations", computationName),
               renvToLoad = runFolder,
               madratConfig = madratConfig,
               jobName = paste0("piktests-", computationName, "-", basename(runFolder)),
               executionMode = executionMode)
  }

  return(invisible(runFolder))
}
