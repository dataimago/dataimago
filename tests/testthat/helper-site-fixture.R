# Shared by test-package-site.R and test-package-site-render.R.
make_site_fixture <- function(dir = withr::local_tempdir(.local_envir = parent.frame())) {
  pkg <- file.path(dir, "sitepkg")
  dir.create(file.path(pkg, "man"), recursive = TRUE)
  dir.create(file.path(pkg, "vignettes", "releases"), recursive = TRUE)
  dir.create(file.path(pkg, "man", "figures"), recursive = TRUE)
  writeLines(c(
    "Package: sitepkg", "Version: 1.2-3.0", "Date: 2026-10-01",
    "Title: A Fixture for Site Tests",
    "Description: Synthetic package used by the test suite.",
    "Authors@R: person(\"Ada\", \"Lovelace\", email = \"ada@example.org\", role = c(\"aut\", \"cre\"))",
    "License: MIT + file LICENSE", "Encoding: UTF-8"
  ), file.path(pkg, "DESCRIPTION"))
  writeLines(c(
    "\\name{shout}", "\\alias{shout}", "\\title{Shout a word}",
    "\\usage{shout(x, times = 1L)}",
    "\\arguments{",
    "  \\item{x}{A character vector.}",
    "  \\item{times}{How often, see \\code{\\link{whisper}} and \\code{\\link[stats]{sd}}.}",
    "}",
    "\\value{A character vector.}",
    "\\examples{shout(\"a\")}"
  ), file.path(pkg, "man", "shout.Rd"))
  writeLines(c(
    "\\name{whisper}", "\\alias{whisper}", "\\alias{murmur}", "\\title{Whisper a word}",
    "\\usage{whisper(x)}", "\\arguments{\\item{x}{A word.}}", "\\value{A word.}"
  ), file.path(pkg, "man", "whisper.Rd"))
  writeLines(c(
    "\\name{words}", "\\docType{data}", "\\alias{words}", "\\title{Example words}",
    "\\format{A character vector.}", "\\description{Words.}", "\\keyword{datasets}"
  ), file.path(pkg, "man", "words.Rd"))
  writeLines(c(
    "\\name{hidden}", "\\alias{hidden}", "\\title{Internal helper}",
    "\\usage{hidden()}", "\\description{Internal.}", "\\keyword{internal}"
  ), file.path(pkg, "man", "hidden.Rd"))
  writeLines(c(
    "\\name{sitepkg-package}", "\\docType{package}", "\\alias{sitepkg-package}",
    "\\title{sitepkg: A fixture}",
    "\\description{The fixture. \\if{html}{\\figure{logo.svg}{options: style='float: right' alt='logo' width='120'}}}"
  ), file.path(pkg, "man", "sitepkg-package.Rd"))
  news <- c("# sitepkg 1.2-3.0", "", "## New", "", "* Louder.", "", "# sitepkg 1.0-0.0", "", "* First.")
  writeLines(news, file.path(pkg, "NEWS.md"))
  vig <- c(
    "---", "title: \"Getting started\"", "output: rmarkdown::html_vignette",
    "vignette: >", "  %\\VignetteIndexEntry{Getting started}", "---", "", "Hello.", ""
  )
  writeLines(vig, file.path(pkg, "vignettes", "sitepkg.Rmd"))
  writeLines(c("---", "title: \"Release 1.2\"", "---", "", "Notes."), file.path(pkg, "vignettes", "releases", "r12.Rmd"))
  svg <- "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 10 10\"><path d=\"M0 0h10v10z\"/></svg>"
  writeLines(svg, file.path(pkg, "man", "figures", "logo.svg"))
  readme <- c(
    "sitepkg", "=======", "", "[![CRAN](x.svg)](y)", "", "Shout and whisper words.", "",
    "## Installation", "", "```r", "install.packages(\"sitepkg\")", "```", "",
    "## Usage", "", "`shout(\"a\")`"
  )
  writeLines(readme, file.path(pkg, "README.md"))
  pkg
}
