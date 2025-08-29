pkgname <- "dataimago"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('dataimago')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("build_design_system")
### * build_design_system

flush(stderr()); flush(stdout())

### Name: build_design_system
### Title: Build Design System Assets
### Aliases: build_design_system
### Keywords: build-tools css design-system ethical-ai

### ** Examples

## Not run: 
##D # Basic build - compile all assets
##D result <- build_design_system()
##D 
##D # Check if build succeeded
##D if (result$success) {
##D   cat("Success: Built assets:", paste(result$assets, collapse = ", "), "\n")
##D   cat("SRI hashes:", length(result$sri_hashes), "generated\n")
##D } else {
##D   cat("ERROR: Build failed:", paste(result$errors, collapse = "; "), "\n")
##D }
##D 
##D # Force rebuild with verbose output (useful for debugging)
##D result <- build_design_system(force_rebuild = TRUE, verbose = TRUE)
##D 
##D # Build for CDN distribution only (skip local copying)
##D result <- build_design_system(
##D   include_sri = TRUE,
##D   update_extension = FALSE,
##D   verbose = FALSE
##D )
##D 
##D # Inspect build metadata
##D str(result$metadata)
## End(Not run)




cleanEx()
nameEx("create_quarto_documentation")
### * create_quarto_documentation

flush(stderr()); flush(stdout())

### Name: create_quarto_documentation
### Title: Generate Quarto Documentation from R Package
### Aliases: create_quarto_documentation
### Keywords: documentation ethical-ai generation quarto

### ** Examples

## Not run: 
##D # Basic usage - generate documentation for current package
##D create_quarto_documentation()
##D 
##D # Generate for specific package with custom output location
##D create_quarto_documentation(
##D   package_path = "/path/to/my/package",
##D   output_path = "docs/website"
##D )
##D 
##D # Generate minimal documentation without foundation links
##D create_quarto_documentation(
##D   include_foundation_links = FALSE,
##D   include_description = FALSE
##D )
##D 
##D # For MCP/AI usage - capture output path
##D doc_path <- create_quarto_documentation()
##D cat("Generated documentation at:", doc_path)
## End(Not run)




cleanEx()
nameEx("create_ui_workspace")
### * create_ui_workspace

flush(stderr()); flush(stdout())

### Name: create_ui_workspace
### Title: Create UI Workspace for Design System
### Aliases: create_ui_workspace

### ** Examples

## Not run: 
##D # Create new ui workspace
##D result <- create_ui_workspace()
##D 
##D # Force recreate existing workspace
##D result <- create_ui_workspace(force_overwrite = TRUE)
##D 
##D # Check what was created
##D if (result$success) {
##D   cat("Created files:", paste(result$created_files, collapse = "\n  "))
##D }
## End(Not run)




cleanEx()
nameEx("update_quarto_extension")
### * update_quarto_extension

flush(stderr()); flush(stdout())

### Name: update_quarto_extension
### Title: Update Quarto Extension Assets
### Aliases: update_quarto_extension

### ** Examples

## Not run: 
##D # Update extension after building CSS
##D build_design_system()
##D result <- update_quarto_extension()
##D 
##D # Check what was updated
##D if (result$success) {
##D   cat(
##D     "Updated files:",
##D     paste(result$updated_files, collapse = "\n  ")
##D   )
##D }
## End(Not run)




### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
