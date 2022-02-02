test_that("run works", {
  skip_on_ci()
  if (startsWith(renv::paths$cache(), tempdir())) {
    cat(paste0("\nWith your setup the renv cache is not used in tests, so this test will take a very long time. ",
               "To change this, cancel testing and run the following before running tests again:\n",
               "Sys.setenv(RENV_PATHS_ROOT=renv::paths$root())"))
  }
  withr::local_options(repos = c(rse = "https://rse.pik-potsdam.de/r/packages", cran = "https://cran.rstudio.com/"))
  tempFolder <- withr::local_tempdir()
  runFolder <- run(computationNames = "madratExample", renvInstallPackages = "magclass@6.0.9",
                   piktestsFolder = tempFolder, executionMode = "directly")
  expect_true(dir.exists(file.path(runFolder, "madratMainFolder")))
  expect_equal(length(Sys.glob(file.path(runFolder, "madratMainFolder", "output", "*.tgz"))), 1)
  expect_true(file.exists(file.path(runFolder, "madratConfig.rds")))
  expect_true(file.exists(file.path(runFolder, "optionsEnvironmentVariablesLocale.rds")))
  expect_equal(length(Sys.glob(file.path(runFolder, "computations", "madratExample", "*.log"))), 1)
  expect_true(dir.exists(file.path(runFolder, "renv")))
  expect_true(file.exists(file.path(runFolder, "renv.lock")))

  dir.create(file.path(tempFolder, format(Sys.time(), "%Y_%m_%d-%H_%M")), showWarnings = FALSE)
  expect_error(run(computationNames = "madratExample", piktestsFolder = tempFolder,
                   executionMode = "directly"), "already exists!")
})
