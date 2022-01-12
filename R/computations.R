#' computations
#'
#' A list of computation objects to be used by \code{\link{run}} via the `whatToRun` parameter.
#'
#' Each computation object is a list with a setup and a compute function. These are called at the appropriate times
#' during a piktests \code{\link{run}}.
#'
#' @author Pascal Führlich
#'
#' @examples
#' \dontrun{
#' piktests::run(whatToRun = piktests::computations["magpiePreprocessing"])
#' }
#'
#' @importFrom gert git_clone
#' @importFrom madrat retrieveData
#' @importFrom renv install
#' @export
computations <- list(
  # setup and compute functions run in a separate R session, so they must use `::` instead of roxygen's `@importFrom`
  magpiePreprocessing = list(
    setup = function(workingDirectory) {
      renv::install("gert")
      gert::git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git",
                      path = file.path(workingDirectory, "preprocessing-magpie"))
      # renv::install not necessary, because this is run before renv auto-detects and installs dependencies
    },
    compute = function() {
      source(file.path("start", "default.R")) # nolint
    }
  ),
  remindPreprocessing = list(
    setup = function(workingDirectory) {
      renv::install("mrremind")
    },
    compute = function() {
      # sidestep package check warning (mrremind not in DESCRIPTION); ok because setup installs mrremind
      library(paste("mrremind"), character.only = TRUE) # nolint
      madrat::retrieveData("remind", cachetype = "def")
    }
  ),
  madratExample = list(
    setup = function(workingDirectory) {
      renv::install("madrat")
    },
    compute = function() {
      library("madrat") # nolint
      madrat::retrieveData("example", cachetype = "def")
    }
  )
)
