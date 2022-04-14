#' baseComputations
#'
#' A list of computation objects to be used by \code{\link{run}} via the `whatToRun` parameter.
#'
#' Each computation object is a list with a setup and a compute function. These are called at the appropriate times
#' during a piktests \code{\link{run}}.
#'
#' @author Pascal Führlich
#'
#' @importFrom madrat retrieveData
#' @importFrom renv install
#' @export
baseComputations <- list(
  # Setup and compute functions run in a separate R session, so they must use `::` instead of roxygen's `@importFrom`.
  magpiePrep = list(
    setup = function() {
      renv::install("gert")
      gert::git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git", path = "preprocessing-magpie")
      # further renv::install not necessary, because this is run before renv auto-detects and installs dependencies
    },
    compute = function() {
      withr::local_dir("preprocessing-magpie")
      source(file.path("start", "default.R")) # nolint
    }
  ),
  remindPrep = list(
    setup = function() {
      renv::install("gert")
      gert::git_clone("git@gitlab.pik-potsdam.de:REMIND/preprocessing-remind.git", path = "preprocessing-remind")
      # further renv::install not necessary, because this is run before renv auto-detects and installs dependencies
    },
    compute = function() {
      source(file.path("preprocessing-remind", "start.R")) # nolint
    }
  ),
  edgebuildingsPrep = list(
    setup = function() {
      renv::install("mredgebuildings")
    },
    compute = function() {
      withr::local_package("mredgebuildings")
      madrat::retrieveData(model = "edgebuildings", cachetype = "def")
    }
  ),
  testComputation = list(
    setup = function() {
      file.create("setupComplete")
    },
     compute = function() {
       message("computation complete")
     }
  ),
  madratExample = list(
    setup = function() {
      renv::install("madrat")
    },
    compute = function() {
      withr::local_package("madrat")
      madrat::retrieveData("example", cachetype = "def", puc = FALSE)
    }
  )
)
