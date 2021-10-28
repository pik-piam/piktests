test_that("runInNewRSession works properly", {
  workFile <- "test_workFile.rds"
  expect_identical(tail(runInNewRSession(function() 1 + 1, workFileName = workFile, stdout = TRUE, stderr = TRUE,
                                         cleanupWorkFile = FALSE), 1),
                   "[1] 2")
  expect_true(file.exists(workFile))
  expect_identical(tail(runInNewRSession(function(x) 1 + x, list(x = 1), workFileName = workFile, stdout = TRUE,
                                         stderr = TRUE, cleanupWorkFile = TRUE), 1),
                   "[1] 2")
  expect_false(file.exists(workFile))
})

test_that("runInNewRSession works with sbatch", {
  skip_if(Sys.which("sbatch") == "")

  logFile <- withr::local_tempfile()

  runInNewRSession(function() 1 + 1, stdout = NULL, stderr = NULL, useSbatch = TRUE,
                   sbatchArguments = c(paste0("--output=", logFile),
                                       "--mail-type=NONE",
                                       "--wait"))

  expect_true(file.exists(logFile))
  expect_identical(tail(readLines(logFile), 1),
                   "[1] 2")
})

test_that("runInNewRSession detects malformed input", {
  expect_error(runInNewRSession(123),
               "is.function(workFunction) is not TRUE", fixed = TRUE)
  expect_error(runInNewRSession(function() 0, 1),
               "is.list(arguments) is not TRUE", fixed = TRUE)
  expect_error(runInNewRSession(function() 0, workFileName = "./nonexistentpath/bla.rds"),
               "file.create(workFileName, showWarnings = FALSE) is not TRUE", fixed = TRUE)
  expect_error(runInNewRSession(function() 0, useSbatch = NA),
               "isTRUE(useSbatch) || isFALSE(useSbatch) is not TRUE", fixed = TRUE)
  expect_error(runInNewRSession(function() 0, cleanupWorkFile = NA),
               "isTRUE(cleanupWorkFile) || isFALSE(cleanupWorkFile) is not TRUE", fixed = TRUE)
  workFile <- withr::local_tempfile()
  expect_error(runInNewRSession(function() 0, workFileName = workFile, unknownArgument = NULL),
               "unused argument (unknownArgument = NULL)", fixed = TRUE)
})
