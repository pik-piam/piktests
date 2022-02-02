test_that("runLongJob works", {
  expect_identical(runLongJob(function(x, y) x + y, list(y = 3, 5),
                              workingDirectory = withr::local_tempdir(), executionMode = "directly"), 8)

  if (slurmR::slurm_available()) {
    # testthat loads piktests in a weird way, so slurmR cannot load it, so we unload to avoid crashing
    unloadNamespace("piktests")
    withr::with_output_sink(nullfile(), {
      slurmJob <- runLongJob(function() 3 + 5, jobName = "pusteblume")
    })
    library("piktests")
    expect_identical(slurmR::Slurm_collect(slurmJob)[[1]], 8)
    slurmR::Slurm_clean(slurmJob)
    expect_true(file.exists("pusteblume.log"))
    file.remove("pusteblume.log")
  }

  skip_on_ci() # launching new R sessions with callr and using renvs during tests is unstable, so disable on ci
  workFunction <- function() {
    return(list(workingDirectory = getwd(),
                libPaths = .libPaths(),
                madratConfig = getOption("madrat_cfg"),
                renvProject = renv::project()))
  }

  renvProject <- withr::local_tempdir()
  callr::r(function(targetDir) {
    renv::init(targetDir)
    renv::install("withr")
  }, list(renvProject))
  workingDirectory <- withr::local_tempdir()
  x <- runLongJob(workFunction,
                  workingDirectory = workingDirectory,
                  renvToLoad = renvProject,
                  madratConfig = madrat::getConfig(verbose = FALSE),
                  executionMode = "directly")
  expect_identical(normalizePath(x[["workingDirectory"]]), normalizePath(workingDirectory))
  expect_identical(x[["renvProject"]], renvProject)
  expect_true(startsWith(x[["libPaths"]][[1]], renvProject))
  expect_identical(x[["madratConfig"]], madrat::getConfig(verbose = FALSE))
})
