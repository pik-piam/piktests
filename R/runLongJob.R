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
#' @importFrom callr r_bg r
#' @importFrom renv activate
#' @importFrom slurmR opts_slurmR Slurm_lapply
#' @importFrom utils dump.frames
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

  augmentedWorkFunction <- function(renvToLoad, workingDirectory, madratConfig, workFunction, arguments) {
    withr::local_dir(workingDirectory)
    withr::local_options(nwarnings = 10000, error = function() {
      traceback(2, max.lines = 1000)
      dump.frames(to.file = TRUE)
      message("Dumped frames, run `load('", getwd(), "/last.dump.rda'); debugger()` to start debugging")
      quit(save = "no", status = 1, runLast = TRUE)
    })
    if (!is.null(madratConfig)) {
      withr::local_options(madrat_cfg = madratConfig)
    }
    if (!is.null(renvToLoad)) {
      renv::load(renvToLoad)
    }
    result <- do.call(workFunction, arguments)
    print(warnings())
    return(result)
  }

  if (mode == "sbatch") {
    # TODO suppress normalizePath warning
    return(Slurm_lapply(list(augmentedWorkFunction), callr::r, args = list(renvToLoad, workingDirectory, madratConfig, workFunction, arguments),
                     njobs = 1, job_name = jobName, plan = "submit",
                     sbatch_opt = list(`mail-type` = "END",
                                         qos = "priority",
                                         mem = 50000,
                                         output = file.path(workingDirectory, paste0(jobName, ".log")))))
  } else if (mode == "background") {
    return(callr::r_bg(augmentedWorkFunction,
                       list(renvToLoad, workingDirectory, madratConfig, workFunction, arguments)))
  } else {
    return(callr::r(augmentedWorkFunction, list(renvToLoad, workingDirectory, madratConfig, workFunction, arguments)))
  }
}