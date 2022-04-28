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
  # setup and compute functions run in a separate R session, so they must use `::` instead of roxygen's `@importFrom`

  # the following packages are always available: renv, withr, gert, yaml

  # renv will automatically determine and install dependencies after the setup function based on available R files
  # so after e.g. cloning a repository no explicit renv::install for dependencies is needed

  magpiePrep = list(
    setup = function() {
      gert::git_clone("git@gitlab.pik-potsdam.de:landuse/preprocessing-magpie.git", path = "preprocessing-magpie")
    },
    compute = function() {
      withr::local_dir("preprocessing-magpie")
      source(file.path("start", "default.R")) # nolint
    }
  ),
  remindPrep = list(
    setup = function() {
      gert::git_clone("git@gitlab.pik-potsdam.de:REMIND/preprocessing-remind.git", path = "preprocessing-remind")
    },
    compute = function() {
      source(file.path("preprocessing-remind", "start.R")) # nolint
    }
  ),
  remindModel = list(
    setup = function() {
      message("Cloning the REMIND model repository, please wait...")
      # TODO switch to remindmodel/remind
      gert::git_clone("https://github.com/pfuehrlich-pik/remindmodel", branch = "develop", path = "repo")

      renvProject <- normalizePath("..")
      writeLines(paste0("renv::load('", renvProject, "')"),
                 file.path("repo", ".Rprofile"))
    },
    compute = function() {
      withr::local_dir("repo")
      system2("Rscript", "start.R", input = "5") # 5 = SLURM priority, 12 nodes, nash H12
    }
  ),
  magpieModel = list(
    setup = function() {
      gert::git_clone("https://github.com/magpiemodel/magpie", branch = "develop", path = "repo")

      # TODO remove this file.remove when lucode is no longer used in these scripts
      # delete scripts that use the unavailable lucode package
      file.remove(file.path("repo", "scripts", "start", "projects", c("aff_bgp.R",
                                                                      "project_BEST.R",
                                                                      "project_inms2.R")))

      renvProject <- normalizePath("..")
      writeLines(paste0("renv::load('", renvProject, "')"),
                 file.path("repo", ".Rprofile"))
    },
    compute = function() {
      withr::local_dir("repo")
      source(file.path("scripts", "start", "default.R")) # nolint
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
      if (!is.null(renv::project())) {
        renv::settings$use.cache(FALSE)
      }
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
