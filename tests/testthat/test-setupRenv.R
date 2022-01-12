test_that("setupRenv works", {
  skip_on_ci()
  if (startsWith(renv::paths$cache(), tempdir())) {
    cat(paste0("\nWith your setup the renv cache is not used in tests, so this test will take a very long time. ",
               "To change this, cancel testing and run the following before running tests again:\n",
               "Sys.setenv(RENV_PATHS_ROOT=renv::paths$root())"))
  }
  withr::local_options(repos = c(rse = "https://rse.pik-potsdam.de/r/packages", cran = "https://cran.rstudio.com/"))
  renvProject <- withr::local_tempdir()
  whatToRun <- list(testComputation = list(
    setup = function(workingDirectory) {
      renv::install("gert")
      gert::git_clone("https://github.com/pik-piam/universe.git", path = file.path(workingDirectory, "universe"))
    },
    compute = function() NULL
  ))
  callr::r(piktests:::setupRenv, list(renvProject, whatToRun))
  expect_true(dir.exists(file.path(renvProject, "computations", "testComputation", "universe")))
  expect_true(file.exists(file.path(renvProject, "renv.lock")))
  expect_true(dir.exists(file.path(renvProject, "renv")))
})
