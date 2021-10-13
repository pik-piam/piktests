runPreprocessing <- function(package = "mrremind", retrieveDataArgs = "'remind'") {
  stopifnot(length(retrieveDataArgs) == 1)
  command <- paste0("withr::with_options(list(madrat_cfg = readRDS('madratConfig.rds')), { ",
                    "library(", package, "); ",
                    "madrat::retrieveData(", retrieveDataArgs, ") })")
  message("Running ", command)
  logFileName <- file.path("preprocessingLogs", paste0(package, "-", retrieveDataArgs, ".log"))
  # TODO remove timeout; maybe set wait = FALSE
  system2("Rscript", "-", input = command, wait = TRUE, stdout = logFileName, stderr = logFileName, timeout = 20)
}
