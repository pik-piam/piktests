#' @importFrom withr local_tempfile
runPreprocessing <- function(madratConfig, package, retrieveDataArgs) {
  stopifnot(requireNamespace(package, quietly = TRUE),
            is.list(retrieveDataArgs), is.character(retrieveDataArgs[[1]]), length(retrieveDataArgs[[1]]) == 1)

  cachetype <- retrieveDataArgs[["cachetype"]]
  if (!is.null(cachetype) && cachetype != "def") {
    warning('Overwriting cachetype: ', cachetype, ' -> "def"')
  }
  retrieveDataArgs["cachetype"] <- "def"

  # written to an RDS file and executed in a new R session, so cannot use @importFrom
  workFunction <- function(arguments) {
    withr::local_options(madrat_cfg = arguments[["madratConfig"]])
    library(arguments[["package"]], character.only = TRUE) # nolint
    # TODO breaks unless pfuehrlich-pik/madrat is merged, remove Remotes: pfuehrlich-pik/madrat from DESCRIPTION
    do.call(madrat::retrieveData, arguments[["retrieveDataArgs"]])
  }

  preprocessingFileNameBase <- file.path("preprocessings", paste0(package, "-", retrieveDataArgs[[1]]))

  workFile <- paste0(preprocessingFileNameBase, "_work.rds")
  saveRDS(list(workFunction = workFunction,
               arguments = list(madratConfig = madratConfig, package = package, retrieveDataArgs = retrieveDataArgs)),
          workFile)
  logFileName <- paste0(preprocessingFileNameBase, ".log")
  # TODO wait = FALSE does not work, probably because the shell immediately closes and all child processes die
  system2("Rscript", c("-e", shQuote(paste0("work <- readRDS('", workFile, "'); ",
                                            "work[['workFunction']](work[['arguments']])"))), # TODO add call to warnings()
          stdout = logFileName, stderr = logFileName)
}
