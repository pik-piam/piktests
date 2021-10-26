#' runInRenv
#'
#' Creates a test run folder, sets up a fresh renv and installs needed packages in it. Then calls piktests:::run() to
#' run the actual tests.
#'
#' @param useSbatch Whether to start the tests via sbatch (run in background) or directly in the current shell. If NA
#' the user is asked.
#'
#' @importFrom madrat getConfig
#' @importFrom utils packageDescription
#' @importFrom withr local_dir
#' @export
runInRenv <- function(useSbatch = NA) {
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

  if (isTRUE(useSbatch) || is.na(useSbatch) && tolower(readline("Run via sbatch? (Y/n)")) %in% c("y", "yes", "")) {
    sbatchArgs <- c(paste0("--job-name=piktests-", now),
                    "--output=runInRenv.log",
                    "--mail-type=END",
                    "--qos=priority",
                    "--mem=32000",
                    paste0("--wrap='Rscript -e \"piktests:::run()\"'"))
    message("Running `sbatch ", paste(sbatchArgs, collapse = " "), "`")
    system2("sbatch", sbatchArgs)
  } else {
    message("Running `Rscript installDependenciesAndRun.R`")
    system2("Rscript", "-", input = "piktests:::run()")
  }
}
