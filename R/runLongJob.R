#' @importFrom callr r_bg r
#' @importFrom renv activate
#' @importFrom slurmR opts_slurmR Slurm_EvalQ
#' @importFrom utils dump.frames
#' @importFrom withr local_dir local_options
runLongJob <- function(renvToActivate,
                       workingDirectory,
                       madratConfig,
                       workFunction,
                       arguments = NULL,
                       mode = c("sbatch", "parallel", "sequential"),
                       jobName = opts_slurmR$get_job_name()) {
  mode <- match.arg(mode)
  if (mode == "sbatch" && Sys.which("sbatch") == "") {
    warning("sbatch is unavailable, falling back to parallel execution")
    mode <- "parallel"
  }

  augmentedWorkFunction <- function(renvToActivate, workingDirectory, madratConfig, workFunction, arguments) {
    renv::activate(renvToActivate)
    withr::local_dir(workingDirectory)
    withr::local_options(madrat_cfg = madratConfig, nwarnings = 10000, error = function() {
      traceback(2, max.lines = 1000)
      dump.frames(to.file = TRUE)
      quit(save = "no", status = 1, runLast = TRUE)
    })

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
