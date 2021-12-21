test_that("runLongJob works", {
  expect_identical(piktests:::runLongJob(function(x, y) x + y, list(y = 3, 5), mode = "directly"), 8)
  expect_identical(piktests:::runLongJob(function() 3 + 5, mode = "background")$wait(3000)$get_result(), 8)

  if (Sys.which("sbatch") == "") {
    expect_warning(piktests:::runLongJob(function() 0),
                   "sbatch is unavailable, falling back to background execution (callr::r_bg)", fixed = TRUE)
  } else {
    expect_identical(slurmR::Slurm_collect(piktests:::runLongJob(function() 3 + 5))[[1]], 8)
  }

  workFunction <- function() {
    return(list(workingDirectory = getwd(),
                libPaths = .libPaths(),
                madratConfig = getOption("madrat_cfg")))
  }
  renvProject <- callr::r(function(targetDir) renv::init(targetDir), list(withr::local_tempdir()))
  x <- piktests:::runLongJob(workFunction,
                             workingDirectory = tempdir(),
                             renvToLoad = renvProject,
                             madratConfig = madrat::getConfig(verbose = FALSE),
                             mode = "directly")
  expect_identical(normalizePath(x[["workingDirectory"]]), normalizePath(tempdir()))
  expect_identical(normalizePath(x[["libPaths"]][[1]]),
                   normalizePath(file.path(renvProject, "renv", "library", "R-4.1", "x86_64-pc-linux-gnu")))
  expect_true(endsWith(x[["libPaths"]][[2]], "renv-system-library"))
  expect_identical(x[["madratConfig"]], madrat::getConfig(verbose = FALSE))
})
