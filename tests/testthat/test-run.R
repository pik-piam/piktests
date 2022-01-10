test_that("run works", {
  tempFolder <- withr::local_tempdir()
  runFolder <- piktests::run(piktestsFolder = tempFolder, whatToRun = NULL,
                             runInNewRSession = function(...) invisible(NULL), # effectively skip renv setup
                             executionMode = "directly")
  expect_true(dir.exists(file.path(runFolder, "madratCacheFolder")))
  expect_true(dir.exists(file.path(runFolder, "madratOutputFolder")))
  expect_true(file.exists(file.path(runFolder, "madratConfig.rds")))
  expect_true(file.exists(file.path(runFolder, "optionsEnvironmentVariablesLocale.rds")))

  dir.create(file.path(tempFolder, format(Sys.time(), "%Y_%m_%d-%H_%M")), showWarnings = FALSE)
  expect_error(piktests::run(piktestsFolder = tempFolder, executionMode = "directly"), "already exists!")
})
