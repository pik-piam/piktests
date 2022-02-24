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
      preprocessingRemindHash <- "07b2dd389691e659efac0c32949caa1047b26228"
      if (gert::git_commit_id(repo = "preprocessing-remind") != preprocessingRemindHash) {
        warning("https://gitlab.pik-potsdam.de/REMIND/preprocessing-remind was changed, but ",
                "piktests is still using the old version at commit ", preprocessingRemindHash)
      }
      unlink("preprocessing-remind", recursive = TRUE)
      renv::install("mrremind")
    },
    compute = function() {
      withr::local_package("mrremind")
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
  edgebuildingsPrep = list(
    setup = function() {
      renv::install("mredgebuildings")
    },
    compute = function() {
      withr::local_package("mredgebuildings")
      madrat::retrieveData(model = "edgebuildings", cachetype = "def")
    }
  ),
  madratExample = list(
    setup = function() {
      renv::install("madrat")
    },
    compute = function() {
      withr::local_package("madrat")
      madrat::retrieveData("example", cachetype = "def")
    }
  )
)
