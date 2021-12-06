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
    if (Sys.which("sbatch") == "") {
      useSbatch <- FALSE
    } else {
      useSbatch <- tolower(readline("Run via SLURM (sbatch)? (Y/n)")) %in% c("y", "yes", "")
    }
  }

  runFolder <- file.path(getwd(), format(Sys.time(), "%Y_%m_%d-%H_%M"))
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder)
  message("Runfolder ", runFolder, " created.")

  # initialize madrat config
  getConfig(print = TRUE)

  runInNewRSession(function(runFolder) {
    git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git",
              path = file.path(runFolder, "preprocessings", "magpie", "preprocessing-magpie"))
    renv::init(runFolder, restart = FALSE, bare = TRUE) # remove bare when newest foreign can be installed on cluster
  }, list(runFolder = runFolder))

  # install right away, because installing requires internet connection which is not available when running via sbatch
  runInNewRSession(function(runFolder) {
    # TODO remove this when newest foreign can be installed on cluster
    renv::install("foreign@0.8-76")
    dependencies <- renv::dependencies(runFolder, errors = "fatal")
    renv::install(unique(dependencies[["Package"]]))
    # remove until here

    renv::install("mrremind")

    renv::snapshot(type = "all")

    # initialize madrat config
    madrat::getConfig(verbose = FALSE)

    # not used further, just for archiving/looking up later
    saveRDS(list(options = options(), # nolint
                 environmentVariables = Sys.getenv(),
                 locale = Sys.getlocale()),
            file.path(runFolder, "optionsEnvironmentVariablesLocale.rds"))
  }, list(runFolder = runFolder), renvProject = runFolder)

  run(useSbatch = useSbatch, madratConfig = getOption("madrat_cfg"), runFolder = runFolder)
}
