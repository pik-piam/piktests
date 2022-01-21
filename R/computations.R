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
#' @importFrom madrat retrieveData
#' @importFrom renv install
#' @export
computations <- list(
  # setup and compute functions run in a separate R session, so they must use `::` instead of roxygen's `@importFrom`
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
      if (gert::git_commit_id(repo = "preprocessing-remind") != "f3107d60c89d483f869f3286f649be569cc94aee") {
        warning("https://gitlab.pik-potsdam.de/REMIND/preprocessing-remind was changed, but",
                "piktests is still using the old version.")
      }
      unlink("preprocessing-remind", recursive = TRUE)
      renv::install("mrremind")
    },
    compute = function() {
      # paste("mrremind") to sidestep mrremind not in DESCRIPTION warning; mrremind will be installed by setupRenv
      library(paste("mrremind"), character.only = TRUE) # nolint
      lapply(c("regionmappingH12.csv",
               "regionmappingREMIND.csv",
               "regionmapping_21_EU11.csv",
               "regionmappingH12_Aus.csv"),
             function(regionmapping) {
               madrat::retrieveData(model = "REMIND", regionmapping = regionmapping, rev = 6.00, cachetype = "def")
             })
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
  )
)
