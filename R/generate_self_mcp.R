#' @importFrom jsonlite toJSON
#' @importFrom fs path file_exists dir_exists
#' @importFrom glue glue
NULL

#' Generate dataimago Self-Description MCP Tools
#'
#' Creates MCP tool definitions for dataimago itself, enabling AI agents
#' to use dataimago to scaffold, build, and inspect projects programmatically.
#' This closes the recursive loop: dataimago produces tools, and dataimago
#' itself is a tool that AI agents can invoke.
#'
#' @param output_path Character. Path to write the self-description MCP JSON.
#'   Default: "dataimago-mcp-schema.json" in the package installation directory.
#' @param verbose Logical. Print progress. Default: TRUE
#'
#' @return List with the MCP schema and output path
#'
#' @details
#' The self-description MCP schema exposes three tools:
#'
#' - **dataimago_scaffold**: Create a new AI-native application from an R package
#' - **dataimago_build**: Build/rebuild an existing dataimago project
#' - **dataimago_status**: Check build, ethical compliance, and deployment status
#'
#' These tools correspond to the main `ai()`, `build_design_system()`, and
#' status-checking functions in the dataimago R package.
#'
#' @examples
#' \dontrun{
#' # Generate MCP self-description
#' generate_self_mcp("./dataimago-mcp-schema.json")
#' }
#'
#' @export
generate_self_mcp <- function(output_path = NULL, verbose = TRUE) {
  if (verbose) ui_info("Generating dataimago self-description MCP tools...")

  schema <- list(
    `_comment` = "MCP tool definitions for the dataimago meta-tool framework",
    `_generated_by` = "dataimago::generate_self_mcp()",
    `_version` = as.character(utils::packageVersion("dataimago")),
    tools = list(
      build_scaffold_tool(),
      build_build_tool(),
      build_status_tool()
    ),
    resources = list(
      list(
        uri = "dataimago://wiki",
        name = "dataimago Knowledge Wiki",
        description = paste0(
          "The dataimago design system knowledge base -- 70+ pages covering ",
          "critical theory, ethical AI, design tokens, implementation patterns, ",
          "and architectural decisions."
        ),
        mimeType = "text/markdown"
      ),
      list(
        uri = "dataimago://foundations",
        name = "dataimago FOUNDATIONS",
        description = paste0(
          "Authoritative human-authored knowledge documents covering philosophy, ",
          "design theory, architecture, governance, and application guidelines."
        ),
        mimeType = "text/markdown"
      )
    ),
    capabilities = list(
      tools = TRUE,
      resources = TRUE,
      prompts = FALSE
    )
  )

  # Write to file if output_path provided
  if (!is.null(output_path)) {
    json_output <- jsonlite::toJSON(schema, auto_unbox = TRUE, pretty = TRUE)
    writeLines(json_output, output_path)
    if (verbose) ui_done(glue::glue("Self-description MCP schema written to {output_path}"))
  }

  if (verbose) {
    ui_done(glue::glue("Generated {length(schema$tools)} self-description MCP tools"))
  }

  invisible(list(
    schema = schema,
    output_path = output_path,
    tools = vapply(schema$tools, function(t) t$name, character(1))
  ))
}


# ====================================================================
# Individual tool definitions
# ====================================================================

build_scaffold_tool <- function() {
  list(
    name = "dataimago_scaffold",
    description = paste0(
      "Create a new AI-native web application from an R package. ",
      "Executes the full dataimago meta-tool pipeline: R functions -> REST API -> ",
      "MCP tools -> TypeScript types -> Web Application. ",
      "The generated application inherits ethical constraints from dataimago-design."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        project_name = list(
          type = "string",
          description = "Name of the project to create (used for directory name and display)"
        ),
        project_path = list(
          type = "string",
          description = "Directory where the project should be created. Defaults to current working directory."
        ),
        source_pkg = list(
          type = "string",
          description = paste0(
            "Path to the source R package whose exported functions drive the generated application. ",
            "This is the 'R as Source of Truth' -- all APIs, MCP tools, types, and UI derive from this package. ",
            "If not provided, creates scaffolding without the derivation pipeline."
          )
        ),
        framework = list(
          type = "string",
          description = "Target framework for the generated application",
          enum = c("quarto", "shiny", "nextjs", "full"),
          default = "quarto"
        ),
        features = list(
          type = "array",
          description = "AI features to include in the generated application",
          items = list(
            type = "string",
            enum = c("chat-interface", "document-analysis", "data-viz", "streaming", "model-management")
          )
        ),
        theme = list(
          type = "string",
          description = "Visual theme for the application",
          enum = c("professional", "academic", "minimal", "ethical"),
          default = "professional"
        )
      ),
      required = list("project_name")
    ),
    # Phase 2e: expose the MCP endpoint the runtime should target when this
    # tool is invoked via HTTP. The `/api/mcp/<tool>` surface is formalized
    # in Phase 5; until then MCP clients fall back to `implementation.r_function`.
    implementation = list(
      type = "nextjs_mcp",
      endpoint = "/api/mcp/dataimago_scaffold",
      method = "POST",
      producer = "default",
      r_function = "dataimago::ai",
      r_package = "dataimago"
    )
  )
}

build_build_tool <- function() {
  list(
    name = "dataimago_build",
    description = paste0(
      "Build or rebuild a dataimago project. Compiles the design system (CSS from tokens), ",
      "regenerates API scaffolding and MCP tools from the source R package, ",
      "and exports static JSON for serverless deployment."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        project_path = list(
          type = "string",
          description = "Root directory of the dataimago project to build. Defaults to current working directory."
        ),
        source_pkg = list(
          type = "string",
          description = "Path to the source R package. If provided, regenerates API/MCP/types."
        ),
        export_static = list(
          type = "boolean",
          description = "Whether to pre-compute static JSON for serverless deployment",
          default = TRUE
        )
      )
    ),
    implementation = list(
      type = "nextjs_mcp",
      endpoint = "/api/mcp/dataimago_build",
      method = "POST",
      producer = "default",
      r_function = "dataimago::build_design_system",
      r_package = "dataimago"
    )
  )
}

build_status_tool <- function() {
  list(
    name = "dataimago_status",
    description = paste0(
      "Check the status of a dataimago project including build state, ",
      "ethical compliance (contrast, motion, bundle size), ",
      "file counts, and deployment readiness."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        project_path = list(
          type = "string",
          description = "Root directory of the dataimago project to inspect. Defaults to current working directory."
        ),
        checks = list(
          type = "array",
          description = "Which checks to run",
          items = list(
            type = "string",
            enum = c("build", "ethical", "deployment", "all")
          ),
          default = list("all")
        )
      )
    ),
    implementation = list(
      type = "nextjs_mcp",
      endpoint = "/api/mcp/dataimago_status",
      method = "GET",
      producer = "default",
      r_function = "dataimago::check_project_status",
      note = "Status function to be implemented"
    )
  )
}
