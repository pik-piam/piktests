#' runInRenv
#'
#' Creates a test run folder, sets up a fresh renv and installs needed packages in it. Then calls piktests:::run() to
#' run the actual tests.
#'
#' @param useSlurm Whether to start the tests via sbatch (run in background) or directly in the current shell.
#'
#' @importFrom madrat getConfig
#' @importFrom utils packageDescription
#' @importFrom withr local_dir
#' @export
runInRenv <- function(useSlurm = FALSE) {
  now <- format(Sys.time(), "%Y_%m_%d-%H_%M")
  runFolder <- file.path(getwd(), now)
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder)
  message("Runfolder ", runFolder, " created.")
  local_dir(runFolder)

  getConfig()
  saveRDS(getOption("madrat_cfg"), "initialMadratConfig.rds")

  system2("Rscript", "-", input = "renv::init()")

  # installation requires internet connection which is not available when running via sbatch
  system2("Rscript", "-", input = paste0("renv::install('pfuehrlich-pik/piktests')\n", # TODO install from main repo
                                        "renv::snapshot()"))

  logFile <- "runInRenv.log"
  if (useSlurm) {
    sbatchArgs <- c(paste0("--job-name=piktests-", now),
                    paste0("--output=", logFile),
                    "--mail-type=END",
                    "--qos=priority",
                    "--mem=32000",
                    paste0("--wrap='Rscript -e \"piktests:::run()\"'"))
    message("Running `sbatch ", paste(sbatchArgs, collapse = " "), "`")
    system2("sbatch", sbatchArgs)
  } else {
    message("Running `Rscript installDependenciesAndRun.R &> ", logFile, " &`")
    system2("Rscript", "-", input = "piktests:::run()", stdout = logFile, stderr = logFile, wait = FALSE)
  }
}
