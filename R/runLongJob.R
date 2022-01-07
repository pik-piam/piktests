#' runLongJob
#'
#' Run a function in a new R session.
#'
#' @param workFunction This function will be run in a new R session, so it must use `::` whenever package functions are
#' used. Also it cannot refer to variables in the outer scope, use the next parameter (arguments) to pass them.
#' @param arguments A list of arguments passed to workFunction.
#' @param workingDirectory The working directory in which workFunction will be called.
#' @param renvToLoad The renv project to load before running workFunction.
#' @param madratConfig A madrat config (as returned by `madrat::getConfig()`) to be used when running workFunction.
#' @param jobName The name of the slurm job. The slurm output file will be called `<jobName>.log`. This has no
#' effect when mode is not "sbatch".
#' @param mode Determines how workFunction is started.
#' "sbatch" -> `slurmR::EvalQ`, "background" -> `callr::r_bg`, "directly" -> `callr::r`
#'
#' @author Pascal Führlich
#'
#' @importFrom callr r_bg r
#' @importFrom renv activate
#' @importFrom slurmR opts_slurmR Slurm_lapply
#' @importFrom utils dump.frames sessionInfo
#' @importFrom withr local_dir local_options
runLongJob <- function(workFunction,
                       arguments = list(),
                       workingDirectory = getwd(),
                       renvToLoad = NULL,
                       madratConfig = NULL,
                       jobName = opts_slurmR$get_job_name(),
                       mode = c("sbatch", "background", "directly")) {
  mode <- match.arg(mode)
  if (mode == "sbatch" && Sys.which("sbatch") == "") {
    warning("sbatch is unavailable, falling back to background execution (callr::r_bg)")
    mode <- "background"
  }

  dir.create(workingDirectory, recursive = TRUE, showWarnings = !dir.exists(workingDirectory))

  augmentedWorkFunction <- function(renvToLoad, workingDirectory, madratConfig, workFunction, arguments) {
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

  if (mode == "sbatch") {
    dir.create(file.path(opts_slurmR$get_tmp_path(), jobName))
    return(Slurm_lapply(list(augmentedWorkFunction), callr::r,
                        args = list(renvToLoad, workingDirectory, madratConfig, workFunction, arguments),
                        njobs = 1, job_name = jobName, plan = "submit",
                        sbatch_opt = list(`mail-type` = "END",
                                          qos = "priority",
                                          mem = 50000,
                                          output = outputFilePath)))
  } else if (mode == "background") {
    return(callr::r_bg(augmentedWorkFunction,
                       list(renvToLoad, workingDirectory, madratConfig, workFunction, arguments),
                       stdout = outputFilePath, stderr = outputFilePath))
  } else {
    return(callr::r(augmentedWorkFunction, list(renvToLoad, workingDirectory, madratConfig, workFunction, arguments),
                    show = TRUE, stdout = outputFilePath, stderr = outputFilePath))
  }
}
