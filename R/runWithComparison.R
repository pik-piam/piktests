#' runWithComparison
#'
#' Starts two piktests runs, one with default packages and another one with renvInstallPackages installed, so they can
#' be compared. Run this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' Use the shell scripts created in the run folder to compare logs after all runs are finished.
#'
#' @param renvInstallPackages Only in the second run, after installing other
#' packages, `renv::install(renvInstallPackages)` is called.
#' @param computationNames A subset of names(piktests::computations). The setup and compute functions of these
#' computations are executed.
#' @param piktestsFolder A new folder is created in the given directory. In that folder two folders called "old"
#' and "new" are created which contain the actual piktests runs.
#' @param diffTool One or more names of command line tools for comparing two text files. The first one that is found
#' via `Sys.which` is used in the comparison shell script. If none is found falls back to "diff".
#' @param ... Additional arguments passed to \code{\link{run}}.
#' @return Invisibly, the path to the folder holding the two actual piktests runs.
#'
#' @author Pascal Führlich
#'
#' @seealso \code{\link{run}}, \code{\link{computations}}
#'
#' @importFrom utils head
#' @export
runWithComparison <- function(renvInstallPackages,
                              computationNames = c("magpiePrep", "remindPrep"),
                              piktestsFolder = getwd(),
                              diffTool = c("delta", "colordiff", "diff"), ...) {
  stopifnot(!is.null(renvInstallPackages))
  runFolder <- createRunFolder(computationNames, piktestsFolder)
  run(computationNames = computationNames, renvInstallPackages = NULL, ...,
      runFolder = file.path(runFolder, "old"), jobNameSuffix = "-old")
  run(computationNames = computationNames, renvInstallPackages = renvInstallPackages, ...,
      runFolder = file.path(runFolder, "new"), jobNameSuffix = "-new")

  # on the cluster default diff does not support colors, so using pascal's delta (fancy diff tool) installation
  diffTool <- if (any(Sys.which(diffTool) != "")) head(diffTool[Sys.which(diffTool) != ""], 1) else "diff"
  for (computationName in computationNames) {
    compareLogsPath <- file.path(runFolder, paste0("compareLogs-", computationName, ".sh"))
    oldLog <- file.path(runFolder, "old", computationName, "job.log")
    newLog <- file.path(runFolder, "new", computationName, "job.log")

    # remove file hashes and runtimes before comparing
    writeLines(c("#!/usr/bin/env sh",
                 "oldLog=$(mktemp)",
                 "newLog=$(mktemp)",
                 paste0("cp '", file.path(runFolder, "old", "renv.lock"), "' $oldLog"),
                 paste0("cp '", file.path(runFolder, "new", "renv.lock"), "' $newLog"),
                 paste0("sed -r 's/in [0-9.]+ (seconds|Minutes\")$//g' '", oldLog, "' >> $oldLog"),
                 paste0("sed -r 's/in [0-9.]+ (seconds|Minutes\")$//g' '", newLog, "' >> $newLog"),
                 paste0(diffTool, " $oldLog $newLog"),
                 "rm $oldLog $newLog"),
               compareLogsPath)
    system2("chmod", c("+x", compareLogsPath))
  }

  return(invisible(runFolder))
}
