#' computations
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
computations <- list(
  # Setup and compute functions run in a separate R session, so they must use `::` instead of roxygen's `@importFrom`.
  # When adding/changing computations make sure to push to your fork first and then
  # call piktests::run(renvInstallPackages = "<your name>/piktests"), otherwise piktests::computations is taken
  # from pik-piam/piktests.
  magpiePreprocessing = list(
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
  remindPreprocessing = list(
    setup = function() {
      renv::install("gert")
      gert::git_clone("git@gitlab.pik-potsdam.de:REMIND/preprocessing-remind.git", path = "preprocessing-remind")
      if (gert::git_commit_id(repo = "preprocessing-remind") != "07884904b4b86e98b49ec15ea784389285b3049b") {
        warning("https://gitlab.pik-potsdam.de/REMIND/preprocessing-remind was changed, but ",
                "piktests is still using the old version.")
      }
      unlink("preprocessing-remind", recursive = TRUE)
      renv::install("mrremind")
    },
    compute = function() {
      # paste("mrremind") to sidestep mrremind not in DESCRIPTION warning; mrremind will be installed by setupRenv
      library(paste("mrremind"), character.only = TRUE) # nolint
      revision <- "6.278"
      for (mappings in list(c(regionmapping = "regionmappingH12.csv", extramappings = ""),
                            c(regionmapping = "regionmapping_21_EU11.csv", extramappings = ""))) {
        madrat::retrieveData(model = "REMIND", regionmapping = mappings[["regionmapping"]],
                             rev = revision, cachetype = "def")
        madrat::retrieveData(model = "VALIDATIONREMIND", regionmapping = mappings[["regionmapping"]],
                             extramappings = mappings[["extramappings"]], rev = revision, cachetype = "def")
      }
    }
  ),
  madratExample = list(
    setup = function() {
      renv::install("madrat")
    },
    compute = function() {
      library("madrat") # nolint
      madrat::retrieveData("example", cachetype = "def")
    }
  ),
  test = list(
    setup = function() NULL,
    compute = function() {
      message("asdf")
      stop("badum")
      message("tsss")
    }
  )
)
