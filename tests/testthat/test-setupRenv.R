test_that("setupRenv works", {
  withr::local_envvar(RENV_PATHS_CACHE = "~/.local/share/renv/cache")
  withr::local_options(repos = c(rse = "https://rse.pik-potsdam.de/r/packages", cran = "https://cran.rstudio.com/"))
  renvProject <- withr::local_tempdir()
  expect_identical(names(callr::r(piktests:::setupRenv, list(renvProject))), c("R", "Packages"))
  expect_true(file.exists(file.path(renvProject, "renv.lock")))
  expect_true(dir.exists(file.path(renvProject, "renv")))
})
