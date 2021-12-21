#' runLongJob
#'
#' Run a function in a new R session.
#'
#' @importFrom callr r_bg r
#' @importFrom renv activate
#' @importFrom slurmR opts_slurmR Slurm_EvalQ
#' @importFrom utils dump.frames
#' @importFrom withr local_dir local_options
runLongJob <- function(workFunction,
                       arguments = NULL,
                       workingDirectory = getwd(),
                       renvToActivate = NULL,
                       madratConfig = NULL,
                       jobName = opts_slurmR$get_job_name(),
                       mode = c("sbatch", "parallel", "sequential")) {
  mode <- match.arg(mode)
  if (mode == "sbatch" && Sys.which("sbatch") == "") {
    warning("sbatch is unavailable, falling back to parallel execution")
    mode <- "parallel"
  }

  augmentedWorkFunction <- function(renvToActivate, workingDirectory, madratConfig, workFunction, arguments) {
    if (!is.null(renvToActivate)) {
      renv::activate(renvToActivate)
    }
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

    do.call(workFunction, arguments)

    print(warnings())
  }

  if (mode == "sbatch") {
    Slurm_EvalQ(expr = {
                  augmentedWorkFunction(renvToActivate, workingDirectory, madratConfig, workFunction, arguments)
                },
                njobs = 1,
                job_name = jobName,
                plan = "submit",
                sbatch_opt = c("--mail-type=END",
                               "--qos=priority",
                               "--mem=50000",
                               paste0("--output=", jobName, ".log")))
  } else if (mode == "parallel") {
    callr::r_bg(augmentedWorkFunction, list(renvToActivate, workingDirectory, madratConfig, workFunction, arguments))
  } else {
    callr::r(augmentedWorkFunction, list(renvToActivate, workingDirectory, madratConfig, workFunction, arguments))
  }
}
