#' @importFrom madrat retrieveData
#' @importFrom withr local_tempfile local_options
runPreprocessing <- function(madratConfig, package, retrieveDataArgs, useSbatch) {
  stopifnot(requireNamespace(package, quietly = TRUE),
            is.list(retrieveDataArgs), is.character(retrieveDataArgs[[1]]), length(retrieveDataArgs[[1]]) == 1)

  cachetype <- retrieveDataArgs[["cachetype"]]
  if (!is.null(cachetype) && cachetype != "def") {
    warning("Overwriting cachetype: ", cachetype, " -> def")
  }
  retrieveDataArgs["cachetype"] <- "def"

  # written to an RDS file and executed in a new R session, so cannot use @importFrom
  workFunction <- function(arguments) {
    withr::local_options(madrat_cfg = arguments[["madratConfig"]], nwarnings = 10000, error = function() {
      traceback(2, max.lines = 1000)
      if (!interactive())
        quit(save = "no", status = 1, runLast = TRUE)
    })
    library(arguments[["package"]], character.only = TRUE) # nolint
    # TODO breaks unless pfuehrlich-pik/madrat is merged, remove Remotes: pfuehrlich-pik/madrat from DESCRIPTION
    do.call(madrat::retrieveData, arguments[["retrieveDataArgs"]])
    warnings()
  }

  workFile <- file.path("preprocessings", paste0(package, "-", retrieveDataArgs[[1]], "_work.rds"))

  runInNewRSession(workFunction,
                   list(list(madratConfig = madratConfig, package = package, retrieveDataArgs = retrieveDataArgs)),
                   workFilePath = workFile, cleanupWorkFile = FALSE, useSbatch = useSbatch)
}
