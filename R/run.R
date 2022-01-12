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
#' @param whatToRun A list of computation objects. See \code{\link{computations}}.
#' @param runFolder In general this should be left as default. Where the folder for this piktests run should be created.
#' @param runInNewRSession Exists for testing. A function like `callr::r` taking a function and arguments to execute
#' in a new R session.
#' @param executionMode Determines how long running jobs are started. One of "slurm", "background", "directly"
#' @return Invisibly, the path to the folder holding everything related to this piktests run.
#'
#' @author Pascal Führlich
#'
#' @importFrom callr r
#' @importFrom madrat setConfig
#' @importFrom slurmR slurm_available
#' @export
run <- function(renvInstallPackages = NULL,
                piktestsFolder = getwd(),
                whatToRun = computations[c("magpiePreprocessing", "remindPreprocessing")],
                runFolder = file.path(piktestsFolder, format(Sys.time(), "%Y_%m_%d-%H_%M")),
                runInNewRSession = callr::r,
                executionMode = c("slurm", "background", "directly")) {
  whatToRunFormatCheck <- try({
    stopifnot(all(vapply(whatToRun, function(computation) is.function(computation[["setup"]]), logical(1))))
    stopifnot(all(vapply(whatToRun, function(computation) is.function(computation[["compute"]]), logical(1))))
    stopifnot(all(vapply(seq_along(whatToRun),
                         function(i) identical(whatToRun[[i]], whatToRun[[names(whatToRun)[[i]]]]), logical(1))))
  }, silent = TRUE)
  if ("try-error" %in% class(whatToRunFormatCheck)) {
    stop("whatToRun is malformed. See `str(piktests::computations['madratExample'])` for a correct example.")
  }
  executionMode <- match.arg(executionMode)
  if (executionMode == "slurm" && !slurm_available()) {
    warning("slurm is unavailable, falling back to background execution (callr::r_bg)")
    executionMode <- "background"
  }
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder, recursive = TRUE)
  runFolder <- normalizePath(runFolder)
  cacheFolder <- file.path(runFolder, "madratCacheFolder")
  dir.create(cacheFolder)
  outputFolder <- file.path(runFolder, "madratOutputFolder")
  dir.create(outputFolder)

  runInNewRSession(setupRenv, list(runFolder, whatToRun, renvInstallPackages), show = TRUE, spinner = FALSE)

  setConfig(cachefolder = cacheFolder, outputfolder = outputFolder, .local = TRUE)
  madratConfig <- getOption("madrat_cfg")
  saveRDS(madratConfig, file.path(runFolder, "madratConfig.rds"))

  # not used further, just for archiving/looking up later
  saveRDS(list(options = options(), # nolint
               environmentVariables = Sys.getenv(),
               locale = Sys.getlocale()),
          file.path(runFolder, "optionsEnvironmentVariablesLocale.rds"))

  for (computationName in names(whatToRun)) {
    runLongJob(whatToRun[[computationName]][["compute"]],
               workingDirectory = file.path(runFolder, "computations", computationName),
               renvToLoad = runFolder,
               madratConfig = madratConfig,
               jobName = paste0("piktests-", computationName, "-", basename(runFolder)),
               executionMode = executionMode)
  }

  return(invisible(runFolder))
}
