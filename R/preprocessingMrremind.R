#' @importFrom madrat setConfig retrieveData
preprocessingMrremind <- function() {
  madrat::setConfig(packages = "mrremind", .local = TRUE)
  retrieveData("remind")
}
