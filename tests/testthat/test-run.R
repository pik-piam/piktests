test_that("run works", {
  skip_on_ci() # launching new R sessions with callr and using renvs during tests is unstable, so disable on ci
  tempFolder <- withr::local_tempdir()
  runFolder <- run(computations = baseComputations["testComputation"],
                   piktestsFolder = tempFolder, executionMode = "directly")
  expect_true(dir.exists(file.path(runFolder, "madratMainFolder")))
  expect_true(file.exists(file.path(runFolder, "madratConfig.rds")))
  expect_true(file.exists(file.path(runFolder, "optionsEnvironmentVariablesLocale.rds")))
  expect_true(file.exists(file.path(runFolder, "testComputation", "setupComplete")))
  expect_true("computation complete" %in% readLines(file.path(runFolder, "testComputation", "job.log")))
  expect_true(dir.exists(file.path(runFolder, "renv")))
  expect_true(file.exists(file.path(runFolder, "renv.lock")))

  runFolder <- piktests:::createRunFolder("madratExample", tempFolder)
  expect_error(piktests:::createRunFolder("madratExample", tempFolder, runFolder), "already exists!")
})
