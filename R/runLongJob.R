#' runLongJob
#'
#' Run a function in a new R session, per default via SLURM (see executionMode). The log will be written to
#' `file.path(workingDirectory, "job.log")`.
#'
#' @param workFunction This function will be run in a new R session, so it must use `::` whenever package functions are
#' used. Also it cannot refer to variables in the outer scope, use the next parameter (arguments) to pass them.
#' @param arguments A list of arguments passed to workFunction.
#' @param workingDirectory The working directory in which workFunction will be called.
#' @param renvToLoad The renv project to load before running workFunction.
#' @param madratConfig A madrat config (as returned by `madrat::getConfig()`) to be used when running workFunction.
#' @param jobName The SLURM job's name.
#' @param executionMode Determines how workFunction is started.
#' "slurm" -> `slurmR::Slurm_lapply`, "directly" -> `callr::r`
#'
#' @author Pascal Führlich
#'
#' @importFrom callr r
#' @importFrom renv load project
#' @importFrom slurmR opts_slurmR Slurm_lapply slurm_available
#' @importFrom utils dump.frames sessionInfo
#' @importFrom withr local_dir local_options with_dir
#' @export
runLongJob <- function(workFunction,
                       arguments = list(),
                       workingDirectory = getwd(),
                       renvToLoad = NULL,
                       madratConfig = NULL,
                       jobName = opts_slurmR$get_job_name(),
                       executionMode = c("slurm", "directly")) {
  executionMode <- match.arg(executionMode)
  if (executionMode == "slurm" && !slurm_available()) {
    warning("slurm is unavailable, falling back to direct execution (callr::r)")
    executionMode <- "directly"
  }

  workingDirectory <- normalizePath(workingDirectory)

  dir.create(workingDirectory, recursive = TRUE, showWarnings = !dir.exists(workingDirectory))

  augmentedWorkFunction <- function(i, workingDirectory, madratConfig, workFunction, arguments) {
    # workaround for a crash in mcaffinity(old.aff)
    if (i != 1) {
        return(invisible(NULL))
    }
    withr::local_dir(workingDirectory)
    withr::local_options(nwarnings = 10000, warn = 1)
    if (!is.null(madratConfig)) {
      withr::local_options(madrat_cfg = madratConfig)
    }

    result <- try({
      do.call(workFunction, arguments)
    })
    if (inherits(result, "try-error")) {
      print(result)
      traceback()
      stop(result)
    } else {
      return(result)
    }
  }

  outputFilePath <- file.path(workingDirectory, "job.log")
  if (is.null(renvToLoad)) {
    libPaths <- .libPaths() # nolint
  } else {
    local_dir(renvToLoad) # all following newly started R sessions will automatically init this renv
    libPaths <- r(function() { # get the libPaths set in the renv
      renv::load() # callr overwrites the .libPaths the renv .Rprofile has set, so load again
      return(.libPaths()) # nolint
    })
  }

  if (executionMode == "slurm") {
    suppressSpecificWarnings <- function(expr, regexpr) {
      withCallingHandlers(expr, warning = function(m) {
        if (grepl(regexpr, m[["message"]])) {
          invokeRestart("muffleWarning")
        }
      })
    }
    return(suppressSpecificWarnings({
      # list(1, 2) is a workaround for a crash in mcaffinity(old.aff), length(X) has to be greater than 1
      Slurm_lapply(list(1, 2), augmentedWorkFunction,
                   workingDirectory = workingDirectory, madratConfig = madratConfig,
                   workFunction = workFunction, arguments = arguments,
                   njobs = 1, job_name = jobName, plan = "submit", tmp_path = workingDirectory, overwrite = FALSE,
                   libPaths = libPaths,
                   sbatch_opt = list(`mail-type` = "END",
                                     array = "", # cluster won't send mails if slurmR default `array = "1-1"` is used
                                     qos = "priority",
                                     mem = 50000,
                                     output = outputFilePath))
    }, "No such file or directory")) # warning from normalizePath in Slurm_lapply, path is created after normalizing
  } else {
    return(r(augmentedWorkFunction, list(1, workingDirectory, madratConfig, workFunction, arguments),
             show = !requireNamespace("testthat", quietly = TRUE) || !testthat::is_testing(),
             stdout = outputFilePath, stderr = outputFilePath, libpath = libPaths))
  }
}
