#' runLongJob
#'
#' Run a function in a new R session, per default via slurm (see executionMode).
#'
#' @param workFunction This function will be run in a new R session, so it must use `::` whenever package functions are
#' used. Also it cannot refer to variables in the outer scope, use the next parameter (arguments) to pass them.
#' @param arguments A list of arguments passed to workFunction.
#' @param workingDirectory The working directory in which workFunction will be called.
#' @param renvToLoad The renv project to load before running workFunction.
#' @param madratConfig A madrat config (as returned by `madrat::getConfig()`) to be used when running workFunction.
#' @param jobName The output file will be called `<jobName>.log`. If executionMode is "slurm" this is also the name
#' of the slurm job.
#' @param executionMode Determines how workFunction is started.
#' "slurm" -> `slurmR::Slurm_lapply`, "background" -> `callr::r_bg`, "directly" -> `callr::r`
#'
#' @author Pascal Führlich
#'
#' @importFrom callr r_bg r
#' @importFrom renv activate
#' @importFrom slurmR opts_slurmR Slurm_lapply slurm_available
#' @importFrom utils dump.frames sessionInfo
#' @importFrom withr local_dir local_options
runLongJob <- function(workFunction,
                       arguments = list(),
                       workingDirectory = getwd(),
                       renvToLoad = NULL,
                       madratConfig = NULL,
                       jobName = opts_slurmR$get_job_name(),
                       executionMode = c("slurm", "background", "directly")) {
  executionMode <- match.arg(executionMode)
  stopifnot(executionMode != "slurm" || slurm_available())

  dir.create(workingDirectory, recursive = TRUE, showWarnings = !dir.exists(workingDirectory))

  augmentedWorkFunction <- function(i, renvToLoad, workingDirectory, madratConfig, workFunction, arguments) {
    # workaround for a crash in mcaffinity(old.aff)
    if (i != 1) {
        return(invisible(NULL))
    }
    withr::local_options(nwarnings = 10000, warn = 1, error = function() {
      traceback(2, max.lines = 1000)
      dump.frames(to.file = TRUE)
      message("Dumped frames, run `load('", file.path(getwd(), "last.dump.rda"), "'); debugger()` to start debugging")
      quit(save = "no", status = 1, runLast = TRUE)
    })
    withr::local_dir(workingDirectory)
    if (!is.null(madratConfig)) {
      withr::local_options(madrat_cfg = madratConfig)
    }
    if (!is.null(renvToLoad)) {
      renv::load(renvToLoad)
    }

    # unload all loaded namespaces to prevent a crash when testing a new version of a package also used by piktests
    for (i in seq_along(sessionInfo()[["loadedOnly"]])) {
      for (p in setdiff(names(sessionInfo()[["loadedOnly"]]), "compiler")) {
        try(unloadNamespace(p), silent = TRUE)
      }
    }
    return(do.call(workFunction, arguments))
  }

  outputFilePath <- file.path(workingDirectory, paste0(jobName, ".log"))

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
                   renvToLoad = renvToLoad, workingDirectory = workingDirectory, madratConfig = madratConfig,
                   workFunction = workFunction, arguments = arguments,
                   njobs = 1, job_name = jobName, plan = "submit", tmp_path = workingDirectory, overwrite = FALSE,
                   sbatch_opt = list(`mail-type` = "END",
                                     array = "", # cluster won't send mails if slurmR default `array = "1-1"` is used
                                     qos = "priority",
                                     mem = 50000,
                                     output = outputFilePath))
    }, "No such file or directory")) # warning from normalizePath in Slurm_lapply, path is created after normalizing
  } else if (executionMode == "background") {
    return(r_bg(augmentedWorkFunction,
                list(1, renvToLoad, workingDirectory, madratConfig, workFunction, arguments),
                stdout = outputFilePath, stderr = outputFilePath))
  } else {
    return(r(augmentedWorkFunction, list(1, renvToLoad, workingDirectory, madratConfig, workFunction, arguments),
             show = interactive(), stdout = outputFilePath, stderr = outputFilePath))
  }
}
