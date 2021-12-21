test_that("run works", {
  skip_on_ci() # the landuse preprocessing repo is not publicly available
  if (Sys.getenv("RENV_PATHS_CACHE") == "") {
    cat(paste0("\nThe environment variable RENV_PATHS_CACHE is not set, so the renv cache is not used and ",
               "this test will take a very long time. ",
               "To change this, cancel testing and run the following before running tests again:\n",
               "Sys.setenv(RENV_PATHS_CACHE=renv::paths$root('cache'))"))
  }
  withr::local_options(repos = c(rse = "https://rse.pik-potsdam.de/r/packages", cran = "https://cran.rstudio.com/"))
  tempFolder <- withr::local_tempdir()
  runFolder <- piktests::run(piktestsFolder = tempFolder, whatToRun = NULL)
  expect_true(all(dir.exists(c(runFolder,
                               file.path(runFolder, "madratCacheFolder"),
                               file.path(runFolder, "madratOutputFolder"),
                               file.path(runFolder, "preprocessings", "magpie")))))
  expect_true(all(file.exists(c(file.path(runFolder, "madratConfig.rds"),
                                file.path(runFolder, "optionsEnvironmentVariablesLocale.rds")))))

  dir.create(file.path(tempFolder, format(Sys.time(), "%Y_%m_%d-%H_%M")), showWarnings = FALSE)
  expect_error(piktests::run(piktestsFolder = tempFolder), "already exists!")
})
