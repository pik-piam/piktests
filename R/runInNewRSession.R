#' runInNewRSession
#'
#' Runs the given function with the given arguments in a new R session.
#'
#' An RDS file containing the function and args is created, then a new R session is started via system2. In this new
#' session the RDS file is read and the function executed with the arguments.
#'
#' @param workFunction The function to execute in the new R session. TODO
#' @param arguments A list of arguments that is passed to workFunction.
#' @param workFileName The file name of an RDS file containing workFunction and arguments. This file is read in the new
#' R session.
#' @param ... Additional arguments passed to system2. The most useful arguments are probably stdout and stderr, see
#' documentation for system2.
#' @param cleanupWorkFile Whether to delete the workFile after it has been read in the new R session.
#' @param useSbatch Whether to run the new R session in the background using sbatch.
#' @param sbatchArguments Arguments passed to sbatch. A --wrap argument must not be passed. A --wrap argument running
#' the given function in a new R session is automatically appended.
#' @return The result of the system2 call which is calling Rscript directly or via sbatch.
#' @importFrom withr local_tempfile
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
            is.character(sbatchArguments), !any(startsWith(sbatchArguments, "--wrap")),
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
