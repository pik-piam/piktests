#' runInRenv
#'
#' Creates a test run folder, sets up a fresh renv and installs needed packages in it. Then calls piktests:::run() to
#' run the actual tests.
#'
#' @importFrom madrat getConfig
#' @importFrom utils packageDescription
#' @importFrom withr local_dir
#' @export
runInRenv <- function() { # TODO submit to slurm arg
  runFolder <- file.path(getwd(), format(Sys.time(), "%Y_%m_%d-%H_%M"))
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder)
  local_dir(runFolder)

  getConfig()
  saveRDS(getOption("madrat_cfg"), "initialMadratConfig.rds")

  # copying the piktests DESCRIPTION so renv can automatically determine dependencies
  file.copy(attr(packageDescription("piktests"), "file"), runFolder)
  system2("Rscript", "-", input = "renv::init()")
  # TODO comment in next line, remove copying DESCRIPTION
  # system2("Rscript", "-", input = "renv::record('piktests'); renv::restore(); renv::snapshot()")
  system2("Rscript", "-", input = "renv::restore(); renv::install('/home/pascal/dev/piktests'); piktests:::run()")
}
