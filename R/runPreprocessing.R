#' @importFrom withr local_tempfile
runPreprocessing <- function(madratConfig, package, retrieveDataArgs) {
  stopifnot(is.list(retrieveDataArgs),
            is.null(retrieveDataArgs[["cachetype"]]) || identical(retrieveDataArgs[["cachetype"]], "def"),
            is.character(retrieveDataArgs[[1]]) && length(retrieveDataArgs[[1]]) == 1)

  workFunction <- function(arguments) {
    withr::local_options(madrat_cfg = arguments[["madratConfig"]])
    library(arguments[["package"]], character.only = TRUE)
    retrieveDataArgs <- arguments[["retrieveDataArgs"]]
    retrieveDataArgs["cachetype"] <- "def"
    # TODO breaks before madrat 2.3.4, remove Remotes from DESCRIPTION when madrat 2.3.4 is released
    do.call(madrat::retrieveData, retrieveDataArgs)
  }

  workFile <- local_tempfile()
  saveRDS(list(workFunction = workFunction,
               arguments = list(madratConfig = madratConfig, package = package, retrieveDataArgs = retrieveDataArgs)),
          workFile)
  logFileName <- file.path("preprocessingLogs", paste0(package, "-", retrieveDataArgs[[1]], ".log"))
  system2("Rscript", c("-e", shQuote(paste0("work <- readRDS('", workFile, "'); ",
                                            "work[['workFunction']](work[['arguments']])"))),
          stdout = logFileName, stderr = logFileName, wait = FALSE)
}
