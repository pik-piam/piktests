test_that("runLongJob works", {
  expect_identical(piktests:::runLongJob(function(x, y) x + y, list(y = 3, 5),
                                         workingDirectory = withr::local_tempdir(), mode = "directly"), 8)
  expect_identical(piktests:::runLongJob(function() 3 + 5, workingDirectory = withr::local_tempdir(),
                                         mode = "background")$wait(3000)$get_result(), 8)

  if (Sys.which("sbatch") == "") {
    expect_warning(piktests:::runLongJob(function() 0, workingDirectory = withr::local_tempdir()),
                   "sbatch is unavailable, falling back to background execution (callr::r_bg)", fixed = TRUE)
  } else {
    # testthat loads piktests in a weird way, so slurmR cannot load it, so we unload to avoid crashing
    unloadNamespace("piktests")
    withr::with_output_sink(nullfile(), {
      slurmJob <- piktests:::runLongJob(function() 3 + 5, jobName = "pusteblume")
    })
    library("piktests", character.only = TRUE)
    expect_identical(slurmR::Slurm_collect(slurmJob)[[1]], 8)
    slurmR::Slurm_clean(slurmJob)
    expect_true(file.exists("pusteblume.log"))
    file.remove("pusteblume.log")
  }

  workFunction <- function() {
    return(list(workingDirectory = getwd(),
                libPaths = .libPaths(),
                madratConfig = getOption("madrat_cfg")))
  }
  renvProject <- callr::r(function(targetDir) renv::init(targetDir), list(withr::local_tempdir()))
  workingDirectory <- withr::local_tempdir()
  x <- piktests:::runLongJob(workFunction,
                             workingDirectory = workingDirectory,
                             renvToLoad = renvProject,
                             madratConfig = madrat::getConfig(verbose = FALSE),
                             mode = "directly")
  expect_identical(normalizePath(x[["workingDirectory"]]), normalizePath(workingDirectory))
  expect_true(startsWith(x[["libPaths"]][[1]], renvProject))
  expect_identical(x[["madratConfig"]], madrat::getConfig(verbose = FALSE))
})
