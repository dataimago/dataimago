#' @importFrom fs dir_exists dir_create path file_exists
#' @importFrom glue glue
#' @importFrom jsonlite toJSON
#' @importFrom crayon green silver yellow red bold blue
NULL

# ============================================================================
# generate_types.R -- Generate TypeScript Types and Single-Path API Client
# ============================================================================
#
# Creates TypeScript type definitions from R function signatures and a
# single-path API client that always calls the NextJS API route tree
# (/api/discover, /api/data/<endpoint>, /api/openapi.json). Producer
# selection (static / live / database / composite) happens server-side
# via the DATAIMAGO_PRODUCER environment variable and is invisible to
# the client. This replaces the pre-Phase-2e dual-mode client that
# branched on NEXT_PUBLIC_API_MODE.
#
# Pattern: R function signatures -> TypeScript types + NextJS-calling client
# Reference:
#   - dataimago-design wiki: patterns/producer-driver-pattern.md
#   - apps/template/src/app/api/ (route tree this client targets)
# ============================================================================


#' Generate Shared TypeScript Utilities
#'
#' Creates TypeScript type definitions, API client, and utility functions
#' from an R package's exported functions. The generated code enables
#' type-safe integration between the R analysis layer and NextJS frontend.
#'
#' @param pkg_path Character. Path to the R package source directory
#' @param output_dir Character. Directory for generated TypeScript files
#' @param pkg_name Character. Package name. If NULL, read from DESCRIPTION.
#' @param api_port Integer. Retained for backward compatibility. Since
#'   Phase 2e the emitted client does not talk to the R server directly;
#'   the R server is instead the live-producer driver's backing service.
#'   Default: 8000
#' @param verbose Logical. Print progress. Default: TRUE
#'
#' @return List with: files_created, types_generated, client_mode
#'
#' @details
#' Three files are generated:
#'
#' **types.ts** -- TypeScript interfaces for:
#' - API response structures (matching R function return types)
#' - Parameter types for each function
#' - Common types (ApiResponse, ErrorResponse, DiscoveryResponse)
#' - `ApiMode` / `ApiConfig` retained but marked `@deprecated` for one
#'   minor release; new code must not branch on them
#'
#' **api-client.ts** -- Single-path API client (Phase 2e+):
#' - Always calls the NextJS API route tree:
#'   - `GET /api/discover` for the manifest
#'   - `GET /api/data/<endpoint>` for analysis results
#'   - `GET /api/openapi.json` for the OpenAPI spec
#' - Producer selection (static / live / database / composite) is a
#'   server-only concern (DATAIMAGO_PRODUCER env var); the client never
#'   sees which driver answered
#' - No `fetch` fallback to `/api/*.json` in `public/`; static responses
#'   flow through the NextJS route handler backed by StaticProducerDriver
#'
#' **index.ts** -- Re-exports from types and client
#'
#' @section Phase 2e Semantics:
#' The generated client is intentionally *thin*. It is a typed fetch
#' wrapper over four public NextJS routes. The pre-Phase-2e `mode`
#' constructor argument and `NEXT_PUBLIC_API_MODE` env var now emit
#' deprecation warnings but continue to compile.
#'
#' @export
generate_shared_utils <- function(pkg_path,
                                  output_dir,
                                  pkg_name = NULL,
                                  api_port = 8000L,
                                  verbose = TRUE) {
  # Read package name
  if (is.null(pkg_name)) {
    desc_path <- fs::path(pkg_path, "DESCRIPTION")
    if (fs::file_exists(desc_path)) {
      desc_lines <- readLines(desc_path, warn = FALSE)
      pkg_line <- grep("^Package:", desc_lines, value = TRUE)
      if (length(pkg_line) > 0) {
        pkg_name <- trimws(sub("^Package:\\s*", "", pkg_line[1]))
      }
    }
    if (is.null(pkg_name)) pkg_name <- basename(pkg_path)
  }

  if (verbose) {
    ui_info(glue::glue("\U0001F4DD Generating TypeScript utilities for '{pkg_name}'"))
  }

  # Parse exported functions
  exports <- parse_roxygen_exports(pkg_path, verbose = verbose)

  # Ensure output directory
  if (!fs::dir_exists(output_dir)) {
    fs::dir_create(output_dir, recurse = TRUE)
  }

  files_created <- character(0)

  # Generate types.ts
  types_code <- generate_types_ts(exports, pkg_name)
  types_path <- fs::path(output_dir, "types.ts")
  writeLines(types_code, types_path)
  files_created <- c(files_created, "types.ts")
  if (verbose) ui_done("Generated types.ts")

  # Generate api-client.ts
  client_code <- generate_api_client_ts(exports, pkg_name, api_port)
  client_path <- fs::path(output_dir, "api-client.ts")
  writeLines(client_code, client_path)
  files_created <- c(files_created, "api-client.ts")
  if (verbose) ui_done("Generated api-client.ts (dual-mode)")

  # Generate index.ts
  index_code <- generate_index_ts(exports, pkg_name)
  index_path <- fs::path(output_dir, "index.ts")
  writeLines(index_code, index_path)
  files_created <- c(files_created, "index.ts")
  if (verbose) ui_done("Generated index.ts")

  results <- list(
    files_created = files_created,
    types_generated = length(exports),
    client_mode = "dual (live + static)"
  )

  if (verbose) {
    ui_done(glue::glue("Generated {length(files_created)} TypeScript files"))
  }

  invisible(results)
}


# ============================================================================
# Internal: TypeScript Code Generation
# ============================================================================

#' Generate types.ts content
#' @noRd
generate_types_ts <- function(exports, pkg_name) {
  lines <- c(
    glue::glue("// Auto-generated TypeScript types for {pkg_name}"),
    glue::glue("// Generated by dataimago::generate_shared_utils() (Phase 2e+)"),
    glue::glue("// Date: {Sys.Date()}"),
    "//",
    "// DO NOT EDIT MANUALLY -- regenerate with dataimago::generate_shared_utils()",
    "//",
    "// Producer selection (static / live / database / composite) is a server-only",
    "// concern driven by DATAIMAGO_PRODUCER. See producer-driver-pattern in the wiki.",
    "",
    "// ============================================================================",
    "// Common Types",
    "// ============================================================================",
    "",
    "export interface ApiResponse<T = unknown> {",
    "  status: 'success' | 'error';",
    "  data: T;",
    "  request?: Record<string, string>;",
    "  timestamp?: string;",
    "}",
    "",
    "export interface ErrorResponse {",
    "  status: 'error';",
    "  error: string;",
    "  message: string;",
    "  timestamp?: string;",
    "}",
    "",
    "export interface DiscoveryResponse {",
    "  package_name: string;",
    "  version: string;",
    "  endpoints: EndpointInfo[];",
    "  openapi_url?: string;",
    "  timestamp: string;",
    "}",
    "",
    "export interface EndpointInfo {",
    "  name: string;",
    "  title?: string;",
    "  description?: string;",
    "  path: string;",
    "  method: string;",
    "  params?: ParamInfo[];",
    "}",
    "",
    "export interface ParamInfo {",
    "  name: string;",
    "  type: string;",
    "  description?: string;",
    "  required: boolean;",
    "  default?: string;",
    "  enum?: string[];",
    "}",
    "",
    "// ============================================================================",
    "// Function Parameter Types",
    "// ============================================================================"
  )

  for (fn_name in names(exports)) {
    fn_meta <- exports[[fn_name]]
    interface_name <- to_pascal_case(fn_name)

    lines <- c(
      lines, "",
      glue::glue("/** Parameters for {fn_name}() */"),
      glue::glue("export interface {interface_name}Params {{")
    )

    for (param_name in names(fn_meta$params)) {
      p <- fn_meta$params[[param_name]]
      ts_type <- r_type_to_typescript(p$type, p$enum)
      optional <- if (isTRUE(p$required)) "" else "?"
      desc <- gsub("\\*/", "* /", p$description) # Escape comment-ending

      lines <- c(
        lines,
        glue::glue("  /** {desc} */"),
        glue::glue("  {param_name}{optional}: {ts_type};")
      )
    }

    lines <- c(lines, "}")
  }

  lines <- c(
    lines,
    "",
    "// ============================================================================",
    "// Deprecated — kept for one minor release after Phase 2e",
    "// ============================================================================",
    "",
    "/**",
    " * @deprecated Since Phase 2e: the client no longer branches on mode.",
    " *   Producer selection is server-only via DATAIMAGO_PRODUCER.",
    " */",
    "export type ApiMode = 'live' | 'static';",
    "",
    "/**",
    " * @deprecated Since Phase 2e: kept so existing generated code continues",
    " *   to compile. `mode` is ignored by the client; `baseUrl` is only used",
    " *   by legacy callers constructing the client via the deprecated",
    " *   positional constructor.",
    " */",
    "export interface ApiConfig {",
    "  mode: ApiMode;",
    "  baseUrl: string;",
    "  staticBasePath: string;",
    "}"
  )

  paste(lines, collapse = "\n")
}


#' Generate api-client.ts content
#'
#' Emits a single-path client that always calls the NextJS API route tree:
#'   - GET /api/discover
#'   - GET /api/data/<endpoint>
#'   - GET /api/openapi.json
#'
#' Producer selection (static / live / database / composite) is resolved
#' server-side by `resolveProducerDriver()` in `@dataimago/shared-utils/producers`
#' based on `DATAIMAGO_PRODUCER`. The client never sees it.
#'
#' @noRd
generate_api_client_ts <- function(exports, pkg_name, api_port) {
  # Build function-specific methods
  methods <- character(0)

  for (fn_name in names(exports)) {
    fn_meta <- exports[[fn_name]]
    endpoint <- fn_to_endpoint(fn_name)
    interface_name <- to_pascal_case(fn_name)

    methods <- c(
      methods, "",
      "  /**",
      glue::glue("   * {fn_meta$title}"),
      glue::glue("   * Calls GET /api/data/{endpoint} (NextJS route)."),
      "   * Producer (static | live | database | composite) is chosen server-side.",
      "   */",
      glue::glue("  async {to_camel_case(fn_name)}(params: Partial<{interface_name}Params> = {{}}): Promise<ApiResponse> {{"),
      glue::glue("    return this.request('{endpoint}', params);"),
      "  }"
    )
  }

  methods_str <- paste(methods, collapse = "\n")

  param_imports <- paste(vapply(names(exports), function(fn) {
    paste0("  ", to_pascal_case(fn), "Params,")
  }, character(1)), collapse = "\n")

  lines <- c(
    glue::glue("// Auto-generated single-path API client for {pkg_name} (Phase 2e+)"),
    glue::glue("// Generated by dataimago::generate_shared_utils()"),
    glue::glue("// Date: {Sys.Date()}"),
    "//",
    "// This client is a typed fetch wrapper over four public NextJS routes:",
    "//   GET /api/discover",
    "//   GET /api/data/<endpoint>",
    "//   GET /api/openapi.json",
    "// Producer selection happens server-side via DATAIMAGO_PRODUCER.",
    "//",
    "// DO NOT EDIT MANUALLY -- regenerate with dataimago::generate_shared_utils()",
    "",
    "import type {",
    "  ApiResponse,",
    "  ErrorResponse,",
    "  DiscoveryResponse,",
    "  ApiConfig,",
    "  ApiMode,",
    param_imports,
    "} from './types';",
    "",
    "/**",
    " * Default client options. `baseUrl` is empty in the browser (same-origin",
    " * fetch against the NextJS app) and falls back to NEXT_PUBLIC_APP_URL",
    " * during server-side rendering when the app's own origin is not available.",
    " */",
    "const DEFAULT_BASE_URL: string =",
    "  (typeof process !== 'undefined' && process.env?.NEXT_PUBLIC_APP_URL) || '';",
    "",
    "/** Options accepted by the Phase-2e client constructor. */",
    "export interface ClientOptions {",
    "  /** Override same-origin fetch with an absolute URL. Mainly for SSR / tests. */",
    "  baseUrl?: string;",
    "  /** Default fetch timeout in ms. 0 or undefined disables the timeout. */",
    "  timeoutMs?: number;",
    "}",
    "",
    glue::glue("export class {to_pascal_case(pkg_name)}Client {{"),
    "  private readonly baseUrl: string;",
    "  private readonly timeoutMs: number;",
    "",
    "  constructor(options: ClientOptions | Partial<ApiConfig> = {}) {",
    "    // Back-compat: swallow the deprecated ApiConfig shape.",
    "    const legacy = options as Partial<ApiConfig>;",
    "    if (legacy.mode !== undefined || legacy.staticBasePath !== undefined) {",
    "      if (typeof console !== 'undefined' && typeof console.warn === 'function') {",
    "        console.warn(",
    glue::glue("          '[{to_pascal_case(pkg_name)}Client] `mode` and `staticBasePath` are ignored since Phase 2e. ' +"),
    "            'Producer selection is server-only via DATAIMAGO_PRODUCER.',",
    "        );",
    "      }",
    "    }",
    "    const opts = options as ClientOptions;",
    "    this.baseUrl = (opts.baseUrl ?? legacy.baseUrl ?? DEFAULT_BASE_URL).replace(/\\/$/, '');",
    "    this.timeoutMs = opts.timeoutMs ?? 0;",
    "  }",
    "",
    "  /** Low-level fetch; all route-specific methods funnel through here. */",
    "  private async request<T = unknown>(",
    "    endpoint: string,",
    "    params: Record<string, unknown> = {},",
    "  ): Promise<ApiResponse<T>> {",
    "    const qs = new URLSearchParams();",
    "    for (const [k, v] of Object.entries(params)) {",
    "      if (v !== undefined && v !== null && v !== '') qs.set(k, String(v));",
    "    }",
    "    const query = qs.toString();",
    "    const url = `${this.baseUrl}/api/data/${endpoint}${query ? `?${query}` : ''}`;",
    "    const res = await this.safeFetch(url);",
    "    if (!res.ok) {",
    "      const err = await this.safeJson<ErrorResponse>(res);",
    "      throw new Error(err?.message || `API error: ${res.status}`);",
    "    }",
    "    return (await res.json()) as ApiResponse<T>;",
    "  }",
    "",
    "  private async safeFetch(url: string): Promise<Response> {",
    "    if (this.timeoutMs > 0 && typeof AbortController !== 'undefined') {",
    "      const ctrl = new AbortController();",
    "      const timer = setTimeout(() => ctrl.abort(), this.timeoutMs);",
    "      try {",
    "        return await fetch(url, { signal: ctrl.signal });",
    "      } finally {",
    "        clearTimeout(timer);",
    "      }",
    "    }",
    "    return fetch(url);",
    "  }",
    "",
    "  private async safeJson<T>(res: Response): Promise<T | null> {",
    "    try {",
    "      return (await res.json()) as T;",
    "    } catch {",
    "      return null;",
    "    }",
    "  }",
    "",
    "  // ========================================================================",
    "  // Generated API Methods",
    "  // ========================================================================",
    methods_str,
    "",
    "  /** Discover the endpoint catalog (GET /api/discover). */",
    "  async discover(): Promise<DiscoveryResponse> {",
    "    const url = `${this.baseUrl}/api/discover`;",
    "    const res = await this.safeFetch(url);",
    "    if (!res.ok) throw new Error(`discover failed: ${res.status}`);",
    "    return (await res.json()) as DiscoveryResponse;",
    "  }",
    "",
    "  /** Fetch the OpenAPI document (GET /api/openapi.json). */",
    "  async openapi(): Promise<unknown> {",
    "    const url = `${this.baseUrl}/api/openapi.json`;",
    "    const res = await this.safeFetch(url);",
    "    if (!res.ok) throw new Error(`openapi failed: ${res.status}`);",
    "    return await res.json();",
    "  }",
    "",
    "  /**",
    "   * @deprecated Since Phase 2e: the client no longer tracks a mode.",
    "   *   Retained so legacy callers don't crash; always returns 'static'.",
    "   */",
    "  getMode(): ApiMode { return 'static'; }",
    "",
    "  /**",
    "   * @deprecated Since Phase 2e: always returns false; producer selection",
    "   *   is opaque to the client.",
    "   */",
    "  isLive(): boolean { return false; }",
    "}",
    "",
    "/** Default client instance. */",
    glue::glue("export const apiClient = new {to_pascal_case(pkg_name)}Client();")
  )

  paste(lines, collapse = "\n")
}


#' Generate index.ts re-export file
#' @noRd
generate_index_ts <- function(exports, pkg_name) {
  lines <- c(
    glue::glue("// Auto-generated index for {pkg_name} shared utilities"),
    glue::glue("// Generated by dataimago::generate_shared_utils()"),
    "//",
    "// DO NOT EDIT MANUALLY -- regenerate with dataimago::generate_shared_utils()",
    "",
    "export * from './types';",
    glue::glue("export {{ {to_pascal_case(pkg_name)}Client, apiClient }} from './api-client';")
  )

  paste(lines, collapse = "\n")
}


# ============================================================================
# Internal: Naming Convention Helpers
# ============================================================================

#' Convert to PascalCase (e.g., summarizeAssessment -> SummarizeAssessment)
#' @noRd
to_pascal_case <- function(name) {
  # Handle snake_case
  parts <- strsplit(name, "[_.-]")[[1]]
  paste(vapply(parts, function(p) {
    paste0(toupper(substr(p, 1, 1)), substr(p, 2, nchar(p)))
  }, character(1)), collapse = "")
}


#' Convert to camelCase (e.g., summarize_assessment -> summarizeAssessment)
#' @noRd
to_camel_case <- function(name) {
  # Already camelCase? Keep it
  if (!grepl("[_.-]", name)) {
    return(name)
  }

  parts <- strsplit(name, "[_.-]")[[1]]
  first <- parts[1]
  rest <- vapply(parts[-1], function(p) {
    paste0(toupper(substr(p, 1, 1)), substr(p, 2, nchar(p)))
  }, character(1))

  paste0(first, paste(rest, collapse = ""))
}


#' Convert R type to TypeScript type
#' @noRd
r_type_to_typescript <- function(r_type, enum_vals = NULL) {
  if (!is.null(enum_vals) && length(enum_vals) > 0) {
    return(paste(vapply(enum_vals, function(v) paste0("'", v, "'"), character(1)), collapse = " | "))
  }

  switch(r_type,
    "boolean" = "boolean",
    "integer" = "number",
    "number" = "number",
    "numeric" = "number",
    "array" = "string[]",
    "list" = "Record<string, unknown>",
    "string"
  )
}
