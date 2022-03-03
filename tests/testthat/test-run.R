test_that("run works", {
  skip_on_ci() # launching new R sessions with callr and using renvs during tests is unstable, so disable on ci
  tempFolder <- withr::local_tempdir()
  runFolder <- run(computationNames = "testComputation", piktestsFolder = tempFolder, executionMode = "directly")
  expect_true(dir.exists(file.path(runFolder, "madratMainFolder")))
  expect_true(file.exists(file.path(runFolder, "madratConfig.rds")))
  expect_true(file.exists(file.path(runFolder, "optionsEnvironmentVariablesLocale.rds")))
  expect_true(file.exists(file.path(runFolder, "testComputation", "setupComplete")))
  expect_equal(readLines(file.path(runFolder, "testComputation", "job.log")), "computation complete")
  expect_true(dir.exists(file.path(runFolder, "renv")))
  expect_true(file.exists(file.path(runFolder, "renv.lock")))

  expect_error(run(computationNames = "nonexistantComputation"),
               "Computations not found: nonexistantComputation --- Available computations:")

  runFolder <- piktests:::createRunFolder("madratExample", tempFolder)
  expect_error(piktests:::createRunFolder("madratExample", tempFolder, runFolder))
})
