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
      gert::git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git",
                      path = file.path(workingDirectory, "preprocessing-magpie"))
      # further renv::install not necessary, because this is run before renv auto-detects and installs dependencies
    },
    compute = function() {
      withr::local_dir("preprocessing-magpie")
      source(file.path("start", "default.R")) # nolint
    }
  ),
  remindPreprocessing = list(
    setup = function(workingDirectory) {
      gert::git_clone("git@gitlab.pik-potsdam.de:REMIND/preprocessing-remind.git",
                      path = file.path(workingDirectory, "preprocessing-remind"))
      if (!file.exists(file.path("preprocessing-remind", "start.R")) ||
          tools::md5sum(file.path("preprocessing-remind", "start.R")) != "04c25662fc7960b4f15d97ed49af3168") {
        warning("https://gitlab.pik-potsdam.de/REMIND/preprocessing-remind/-/blob/master/start.R was changed, but",
                "piktests is still using the old version.")
      }
      unlink(file.path(workingDirectory, "preprocessing-remind"), recursive = TRUE)
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
    setup = function(workingDirectory) {
      renv::install("madrat")
    },
    compute = function() {
      library("madrat") # nolint
      madrat::retrieveData("example", cachetype = "def")
    }
  )
)
