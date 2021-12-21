test_that("setupRenv works", {
  if (Sys.getenv("RENV_PATHS_CACHE") == "") {
    cat(paste0("\nThe environment variable RENV_PATHS_CACHE is not set, so the renv cache is not used and ",
              "this test will take a very long time. ",
              "To change this, cancel testing and run the following before running tests again:\n",
              "Sys.setenv(RENV_PATHS_CACHE=renv::paths$root('cache'))"))
  }
  withr::local_options(repos = c(rse = "https://rse.pik-potsdam.de/r/packages", cran = "https://cran.rstudio.com/"))
  renvProject <- withr::local_tempdir()
  expect_identical(names(callr::r(piktests:::setupRenv, list(renvProject))), c("R", "Packages"))
  expect_true(file.exists(file.path(renvProject, "renv.lock")))
  expect_true(dir.exists(file.path(renvProject, "renv")))
})
