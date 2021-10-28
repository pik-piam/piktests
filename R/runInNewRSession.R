#' withr local_tempfile
#' @export
runInNewRSession <- function(workFunction,
                             arguments = list(),
                             workFileName = tempfile("workFile-", getwd(), ".rds"),
                             ...,
                             cleanupWorkFile = TRUE,
                             useSbatch = FALSE,
                             sbatchArguments = c(paste0("--job-name=", shQuote(paste0("runInNewRSession-",
                                                                                      basename(workFileName)))),
                                                 paste0("--output=", shQuote(paste0("runInNewRSession-",
                                                                                    basename(workFileName), ".log"))),
                                                 "--mail-type=END",
                                                 "--qos=priority",
                                                 "--mem=32000")) {
  stopifnot(is.function(workFunction),
            is.list(arguments),
            isTRUE(useSbatch) || isFALSE(useSbatch),
            isTRUE(cleanupWorkFile) || isFALSE(cleanupWorkFile),
            file.create(workFileName, showWarnings = FALSE))

  saveRDS(list(func = workFunction, arguments = arguments), workFileName)

  cleanup <- paste0("if (!file.remove('", workFileName, "')) warning('Could not remove ", workFileName, "')")
  bootstrapScript <- normalizePath(local_tempfile(), winslash = "/", mustWork = FALSE)
  writeLines(c(paste0("work <- readRDS('", workFileName, "')"),
               if (cleanupWorkFile) cleanup else NULL,
               "do.call(work[['func']], work[['arguments']])"),
             bootstrapScript)

  if (useSbatch) {
    sbatchArguments <- c(sbatchArguments, paste0("--wrap=", shQuote(paste("Rscript", bootstrapScript))))
    message("Running sbatch ", paste(sbatchArguments, collapse = " "))
    return(system2("sbatch", sbatchArguments, ...))
  } else {
    message("Running Rscript ", bootstrapScript, ...)
    return(system2("Rscript", bootstrapScript, ...))
  }
}
