test_that("run works", {
  withr::local_envvar(RENV_PATHS_CACHE = "~/.local/share/renv/cache")
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
