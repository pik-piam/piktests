#' runInRenv
#'
#' Creates a test run folder, sets up a fresh renv and installs needed packages in it. Then calls piktests:::run() to
#' run the actual tests.
#'
#' @param useSbatch Whether to start the tests via sbatch (run in background) or directly in the current shell. If NA
#' the user is asked.
#'
#' @importFrom madrat getConfig
#' @importFrom withr local_dir
#' @export
runInRenv <- function(useSbatch = NA) {
  if (is.na(useSbatch)) {
    useSbatch <- tolower(readline("Run via SLURM (sbatch)? (Y/n)")) %in% c("y", "yes", "")
  }

  now <- format(Sys.time(), "%Y_%m_%d-%H_%M")
  runFolder <- file.path(getwd(), now)
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder)
  message("Runfolder ", runFolder, " created.")
  local_dir(runFolder)

  # initialize madrat config
  getConfig(print = TRUE)

  renvProject <- getwd()
  runInNewRSession(function(renvProject) {
    renv::init(renvProject)
  }, list(renvProject = renvProject))

  # install right away, because installing requires internet connection which is not available when running via sbatch
  runInNewRSession(function() {
    renv::install("pfuehrlich-pik/magclass") # TODO remove
    renv::install("pfuehrlich-pik/madrat") # TODO remove
    renv::install("pfuehrlich-pik/piktests") # TODO install from main repo instead of github
    renv::install("rgdal") # TODO remove rgdal dependency in DESCRIPTION once rgdal is a dependency of mrmagpie
    renv::install("lucode2") # needed for magpie preprocessing
    renv::snapshot(type = "all")

    # initialize madrat config
    madrat::getConfig(verbose = FALSE)

    # not used further, just for archiving/looking up later
    saveRDS(list(options = options(), # nolint
                 environmentVariables = Sys.getenv(),
                 locale = Sys.getlocale()),
            "optionsEnvironmentVariablesLocale.rds")
  }, renvProject = renvProject)

  run(useSbatch = useSbatch, madratConfig = getOption("madrat_cfg"), renvProject = renvProject)
}
