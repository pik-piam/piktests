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
  local_dir(runFolder)

  getConfig()
  saveRDS(getOption("madrat_cfg"), "initialMadratConfig.rds")

  # this is executed in the new renv
  writeLines(c("renv::install('pfuehrlich-pik/piktests')",
               "renv::snapshot()",
               "piktests:::run()"),
             "installDependenciesAndRun.R")

  system2("Rscript", "-", input = "renv::init()")

  logFile <- "runInRenv.log"
  if (useSlurm) {
    system2("sbatch", c(paste0("--job-name=piktests-", now),
                        paste0("--output=", logFile),
                        "--mail-type=END",
                        "--qos=priority",
                        "--mem=32000",
                        "--wrap='Rscript installDependenciesAndRun.R'"))
  } else {
    system2("Rscript", "installDependenciesAndRun.R", stdout = logFile, stderr = logFile, wait = FALSE)
  }
}
