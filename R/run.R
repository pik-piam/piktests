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
#' @param jobNameSuffix A suffix to be appended to the SLURM job's name.
#' @param executionMode Determines how long running jobs are started. One of "slurm", "directly"
#' @param localCache If TRUE (default) use a new and empty cache folder, otherwise `getConfig("cachefolder")`.
#' @return Invisibly, the path to the folder holding everything related to this piktests run.
#'
#' @author Pascal Führlich, Jan Philipp Dietrich
#'
#' @seealso \code{\link{computations}}
#'
#' @importFrom callr r
#' @importFrom madrat getConfig setConfig
#' @importFrom withr with_output_sink
#' @export
run <- function(renvInstallPackages = NULL,
                computations = baseComputations[c("magpiePrep", "remindPrep")],
                piktestsFolder = getwd(),
                runFolder = NULL,
                jobNameSuffix = "",
                executionMode = c("slurm", "directly"),
                localCache = TRUE) {
  runFolder <- createRunFolder(names(computations), piktestsFolder, runFolder)

  with_output_sink(file.path(runFolder, "piktestsSetup.log"), split = TRUE, code = {
    executionMode <- match.arg(executionMode)

    # deparsing allows moving code to a new R session without any environments from the original R session attached
    r(setupRenv, list(runFolder, renvInstallPackages, deparse(computations)),
      spinner = FALSE, show = !requireNamespace("testthat", quietly = TRUE) || !testthat::is_testing())

    # use global/preconfigured source and mapping folder
    localConfig(sourcefolder = getConfig("sourcefolder"), mappingfolder = getConfig("mappingfolder"))
    if (!localCache) {
      localConfig(cachefolder = getConfig("cachefolder"))
    }

    madratMainFolder <- file.path(runFolder, "madratMainFolder")
    dir.create(madratMainFolder)
    localConfig(mainfolder = madratMainFolder)
    madratConfig <- getOption("madrat_cfg")
    saveRDS(madratConfig, file.path(runFolder, "madratConfig.rds"))

    # not used further, just for archiving/looking up later
    saveRDS(list(options = options(), # nolint
                 environmentVariables = Sys.getenv(),
                 locale = Sys.getlocale()),
            file.path(runFolder, "optionsEnvironmentVariablesLocale.rds"))
  })

  for (computationName in names(computations)) {
    runLongJob(computations[[computationName]][["compute"]],
               workingDirectory = file.path(runFolder, computationName),
               renvToLoad = runFolder,
               madratConfig = madratConfig,
               jobName = paste0(computationName, jobNameSuffix),
               executionMode = executionMode)
  }

  return(invisible(runFolder))
}
