# dataimago Package Architecture

<!-- Architecture Documentation Badges -->
[![Diagrams](https://img.shields.io/badge/Diagrams-5%20Comprehensive-blue.svg)](#-system-overview)
[![Mermaid](https://img.shields.io/badge/Visualization-Mermaid-orange.svg)](https://mermaid.js.org/)
[![Multi-Layer](https://img.shields.io/badge/Architecture-Multi--Layer-green.svg)](#-system-overview)
[![Philosophical](https://img.shields.io/badge/Integration-Ethical%20AI-purple.svg)](#-key-design-principles)
[![R-First](https://img.shields.io/badge/Philosophy-R%20as%20Truth-red.svg)](#r-first-philosophy)

This document provides comprehensive Mermaid diagrams that illustrate the architecture and workflows of the dataimago R package.

## 🏗️ System Overview

The dataimago package is designed as a multi-layered foundation for emancipatory AI development:

```mermaid
graph TB
    %% Main Package Architecture Overview
    subgraph "R Package Core"
        RP[dataimago Package]
        RF[R Functions]
        RF --> DOC[documentation_utils.R]
        RF --> DS[design_system.R]
        RF --> PKG[dataimago-package.R]
    end

    subgraph "Foundation Layer"
        INST[inst/ Directory]
        INST --> FOUND[dataimago/ Foundations]
        INST --> CDN[quarto-assets/ CDN]
        FOUND --> PHIL[Philosophy & Mission]
        FOUND --> ARCH[Architecture Blueprints]
        FOUND --> ASSETS[Design Assets]
    end

    subgraph "Design System"
        UI[ui/ Node.js Workspace]
        UI --> TOKENS[src/tokens/ JSON]
        UI --> SCSS[src/styles/ SCSS]
        UI --> DIST[dist/ Built Assets]
        
        TOKENS --> SD[Style Dictionary]
        SCSS --> SASS[Sass Compiler]
        SD --> PROPS[CSS Custom Properties]
        SASS --> CSS[Compiled CSS]
        CSS --> POST[PostCSS Optimization]
        POST --> DIST
    end

    subgraph "Distribution Channels"
        DIST --> CDN
        DIST --> EXT[_extensions/ Quarto]
        DIST --> NEXT[Next.js Integration]
    end

    subgraph "Documentation System"
        DOC --> QMD[Quarto Website]
        QMD --> API[API Reference]
        QMD --> FOUNDATIONS[Foundation Docs]
        QMD --> GUIDES[Development Guides]
    end

    subgraph "CI/CD Pipeline"
        GH[GitHub Actions]
        GH --> TEST[Multi-platform Testing]
        GH --> BUILD[Automated Builds]
        GH --> DEPLOY[Website Deployment]
        GH --> RELEASE[CDN Releases]
    end

    %% Connections
    RP --> INST
    RP --> UI
    RF --> QMD
    DS --> UI
    CDN --> JSDELIVR[jsDelivr CDN]
    EXT --> QUARTO[External Quarto Sites]
    NEXT --> APPS[Next.js Applications]

    %% Styling
    classDef rCore fill:#3498db,stroke:#2c3e50,stroke-width:2px,color:#fff
    classDef foundation fill:#e74c3c,stroke:#c0392b,stroke-width:2px,color:#fff
    classDef designSystem fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef distribution fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    classDef documentation fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef cicd fill:#1abc9c,stroke:#16a085,stroke-width:2px,color:#fff

    class RP,RF,DOC,DS,PKG rCore
    class INST,FOUND,PHIL,ARCH,ASSETS foundation
    class UI,TOKENS,SCSS,DIST,SD,SASS,PROPS,CSS,POST designSystem
    class CDN,EXT,NEXT,JSDELIVR,QUARTO,APPS distribution
    class QMD,API,FOUNDATIONS,GUIDES documentation
    class GH,TEST,BUILD,DEPLOY,RELEASE cicd
```

## 🔄 Design System Build Process

The package uses a sophisticated build system that maintains "R as source of truth" while leveraging modern web tooling:

```mermaid
flowchart TD
    %% Design System Build Process
    START([Developer Initiates Build])
    
    subgraph "Input Sources"
        TOKENS[Design Tokens<br/>ui/src/tokens/*.json]
        SCSS[SCSS Styles<br/>ui/src/styles/*.scss]
        CONFIG[Build Configuration<br/>package.json, build.js]
    end

    subgraph "R Interface"
        WORKSPACE[create_ui_workspace<br/>Sets up Node.js environment]
        BUILD[build_design_system<br/>Orchestrates entire pipeline]
        DETECT{Sophisticated<br/>system exists?}
    end

    subgraph "Node.js Processing Pipeline"
        SD[Style Dictionary<br/>Token Processing]
        SASS_COMP[Sass Compiler<br/>SCSS → CSS]
        POSTCSS[PostCSS Pipeline<br/>Optimization]
        
        SD --> CUSTOM_PROPS[CSS Custom Properties]
        SASS_COMP --> COMPILED_CSS[Compiled CSS]
        POSTCSS --> MINIFIED[Minified CSS]
    end

    subgraph "Output Destinations"
        DIST[ui/dist/<br/>Development Assets]
        CDN_ASSETS[inst/quarto-assets/<br/>CDN Distribution]
        QUARTO_EXT[_extensions/<br/>Quarto Extension]
        NEXT_PRESET[tailwind-preset.js<br/>Next.js Integration]
    end

    subgraph "Distribution Channels"
        JSDELIVR[jsDelivr CDN<br/>External Projects]
        QUARTO_SITES[Quarto Websites<br/>Extension Usage]
        NEXTJS_APPS[Next.js Apps<br/>Preset Integration]
        R_PACKAGE[R Package<br/>system.file access]
    end

    %% Flow connections
    START --> BUILD
    BUILD --> DETECT
    DETECT -->|Yes| EXISTING[Use Existing System]
    DETECT -->|No| WORKSPACE
    WORKSPACE --> CREATE_MINIMAL[Create Minimal Fallback]
    EXISTING --> TOKENS
    CREATE_MINIMAL --> TOKENS
    
    TOKENS --> SD
    SCSS --> SASS_COMP
    CONFIG --> SD
    CONFIG --> SASS_COMP
    
    CUSTOM_PROPS --> POSTCSS
    COMPILED_CSS --> POSTCSS
    
    MINIFIED --> DIST
    DIST --> CDN_ASSETS
    DIST --> QUARTO_EXT
    DIST --> NEXT_PRESET
    
    CDN_ASSETS --> JSDELIVR
    CDN_ASSETS --> R_PACKAGE
    QUARTO_EXT --> QUARTO_SITES
    NEXT_PRESET --> NEXTJS_APPS

    %% Decision flows
    DETECT -->|Force Rebuild| WORKSPACE

    %% Styling
    classDef input fill:#3498db,stroke:#2c3e50,stroke-width:2px,color:#fff
    classDef rInterface fill:#e74c3c,stroke:#c0392b,stroke-width:2px,color:#fff
    classDef processing fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef output fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    classDef distribution fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef decision fill:#1abc9c,stroke:#16a085,stroke-width:2px,color:#fff

    class TOKENS,SCSS,CONFIG input
    class WORKSPACE,BUILD,EXISTING,CREATE_MINIMAL rInterface
    class SD,SASS_COMP,POSTCSS,CUSTOM_PROPS,COMPILED_CSS,MINIFIED processing
    class DIST,CDN_ASSETS,QUARTO_EXT,NEXT_PRESET output
    class JSDELIVR,QUARTO_SITES,NEXTJS_APPS,R_PACKAGE distribution
    class DETECT decision
```

## 📖 Documentation Generation Workflow

The package provides sophisticated documentation generation that embeds philosophical context into technical documentation:

```mermaid
graph TB
    %% Documentation Generation Workflow
    subgraph "Input Sources"
        PKG_ROOT[R Package Root]
        DESCRIPTION[DESCRIPTION File]
        RD_FILES[man/*.Rd Files]
        ASSETS[inst/ Assets]
    end

    subgraph "Core Function"
        CREATE_DOC[create_quarto_documentation]
        PARSE_DESC[parse_description_file]
        CONVERT_RD[convert_rd_files_to_qmd]
        GENERATE_API[generate_api_reference_qmd]
        GENERATE_YML[generate_quarto_yml]
    end

    subgraph "Processing Pipeline"
        RD2MD[Rd2md Conversion<br/>Suppressed Warnings]
        POST_PROCESS[post_process_md_to_qmd<br/>Ethical Context Injection]
        ETHICAL_NOTES[Ethical AI Context Boxes]
        FOUNDATION_LINKS[dataimago Foundation Links]
    end

    subgraph "Output Generation"
        API_QMD[api_reference.qmd<br/>Complete API Documentation]
        QUARTO_CONFIG[_quarto.yml<br/>Website Configuration]
        ASSET_COPY[Asset Integration<br/>Logos & Styling]
    end

    subgraph "Philosophical Integration"
        HERMENEUTIC[Hermeneutic Transparency<br/>Meaning & Context]
        POSITIVISTIC[Positivistic Rigor<br/>Technical Accuracy]
        ETHICAL[Ethical Reflexivity<br/>Usage Interrogation]
        ITERATIVE[Iterative Design<br/>Dialectical Progress]
    end

    subgraph "Final Output"
        QUARTO_SITE[Complete Quarto Website]
        STYLED_DOCS[Ethically-Styled Documentation]
        AI_ANNOTATIONS[Machine-Readable Annotations]
        CROSS_REFS[Cross-Referenced Content]
    end

    %% Flow connections
    PKG_ROOT --> CREATE_DOC
    DESCRIPTION --> PARSE_DESC
    RD_FILES --> CONVERT_RD
    ASSETS --> ASSET_COPY
    
    CREATE_DOC --> PARSE_DESC
    CREATE_DOC --> CONVERT_RD
    CREATE_DOC --> GENERATE_API
    CREATE_DOC --> GENERATE_YML
    
    CONVERT_RD --> RD2MD
    RD2MD --> POST_PROCESS
    POST_PROCESS --> ETHICAL_NOTES
    POST_PROCESS --> FOUNDATION_LINKS
    
    PARSE_DESC --> GENERATE_API
    ETHICAL_NOTES --> GENERATE_API
    FOUNDATION_LINKS --> GENERATE_API
    
    GENERATE_API --> API_QMD
    GENERATE_YML --> QUARTO_CONFIG
    ASSET_COPY --> STYLED_DOCS
    
    %% Philosophical integration
    HERMENEUTIC --> POST_PROCESS
    POSITIVISTIC --> RD2MD
    ETHICAL --> ETHICAL_NOTES
    ITERATIVE --> FOUNDATION_LINKS
    
    %% Final outputs
    API_QMD --> QUARTO_SITE
    QUARTO_CONFIG --> QUARTO_SITE
    STYLED_DOCS --> QUARTO_SITE
    QUARTO_SITE --> AI_ANNOTATIONS
    QUARTO_SITE --> CROSS_REFS

    %% Styling
    classDef input fill:#3498db,stroke:#2c3e50,stroke-width:2px,color:#fff
    classDef core fill:#e74c3c,stroke:#c0392b,stroke-width:2px,color:#fff
    classDef processing fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef philosophical fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef output fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    classDef final fill:#1abc9c,stroke:#16a085,stroke-width:2px,color:#fff

    class PKG_ROOT,DESCRIPTION,RD_FILES,ASSETS input
    class CREATE_DOC,PARSE_DESC,CONVERT_RD,GENERATE_API,GENERATE_YML core
    class RD2MD,POST_PROCESS,ETHICAL_NOTES,FOUNDATION_LINKS processing
    class HERMENEUTIC,POSITIVISTIC,ETHICAL,ITERATIVE philosophical
    class API_QMD,QUARTO_CONFIG,ASSET_COPY,STYLED_DOCS output
    class QUARTO_SITE,AI_ANNOTATIONS,CROSS_REFS final
```

## 🎨 UI Workspace Architecture

The Node.js workspace provides sophisticated design system build capabilities:

```mermaid
graph LR
    %% UI Workspace Architecture
    subgraph "Source Files"
        TOKENS_DIR[src/tokens/]
        STYLES_DIR[src/styles/]
        
        TOKENS_DIR --> COLORS[colors.json<br/>Brand Colors]
        TOKENS_DIR --> TYPO[typography.json<br/>Font System]
        TOKENS_DIR --> SPACING[spacing.json<br/>Spacing Scale]
        
        STYLES_DIR --> BASE[base.scss<br/>Foundation]
        STYLES_DIR --> COMP[components.scss<br/>UI Components]
        STYLES_DIR --> UTIL[utilities.scss<br/>Helper Classes]
        STYLES_DIR --> A11Y[accessibility.scss<br/>Ethical AI Features]
    end

    subgraph "Build Tools"
        SD[Style Dictionary<br/>Token Processor]
        SASS[Sass Compiler<br/>SCSS Processor]
        POSTCSS[PostCSS<br/>Optimizer]
        BUILD_SCRIPT[build.js<br/>Orchestrator]
    end

    subgraph "Generated Assets"
        DIST_DIR[dist/]
        
        DIST_DIR --> DEV_CSS[dataimago.css<br/>Development Version]
        DIST_DIR --> PROD_CSS[dataimago.min.css<br/>Production Version]
        DIST_DIR --> TOKEN_CSS[tokens.css<br/>CSS Variables]
        DIST_DIR --> TAILWIND[tailwind-preset.js<br/>Next.js Integration]
        DIST_DIR --> MANIFEST[manifest.json<br/>Build Metadata]
    end

    subgraph "Ethical AI Features"
        WCAG[WCAG AA Compliance<br/>Contrast Requirements]
        MOTION[Reduced Motion<br/>Accessibility]
        HIGH_CONTRAST[High Contrast<br/>Alternative Schemes]
        SEMANTIC[Semantic Naming<br/>Meaningful Tokens]
    end

    subgraph "Distribution"
        CDN_COPY[inst/quarto-assets/<br/>CDN Ready]
        EXT_COPY[_extensions/<br/>Quarto Extension]
        LOCAL[ui/dist/<br/>Local Development]
    end

    %% Processing flow
    COLORS --> SD
    TYPO --> SD
    SPACING --> SD
    SD --> TOKEN_CSS
    
    BASE --> SASS
    COMP --> SASS
    UTIL --> SASS
    A11Y --> SASS
    SASS --> DEV_CSS
    
    DEV_CSS --> POSTCSS
    TOKEN_CSS --> POSTCSS
    POSTCSS --> PROD_CSS
    
    BUILD_SCRIPT --> SD
    BUILD_SCRIPT --> SASS
    BUILD_SCRIPT --> POSTCSS
    BUILD_SCRIPT --> TAILWIND
    BUILD_SCRIPT --> MANIFEST

    %% Ethical features integration
    WCAG --> A11Y
    MOTION --> A11Y
    HIGH_CONTRAST --> A11Y
    SEMANTIC --> COLORS
    SEMANTIC --> TYPO
    SEMANTIC --> SPACING

    %% Distribution
    PROD_CSS --> CDN_COPY
    TOKEN_CSS --> CDN_COPY
    PROD_CSS --> EXT_COPY
    TOKEN_CSS --> EXT_COPY
    DEV_CSS --> LOCAL
    PROD_CSS --> LOCAL
    TOKEN_CSS --> LOCAL
    TAILWIND --> LOCAL

    %% Styling
    classDef source fill:#3498db,stroke:#2c3e50,stroke-width:2px,color:#fff
    classDef build fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef assets fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    classDef ethical fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef distribution fill:#1abc9c,stroke:#16a085,stroke-width:2px,color:#fff

    class TOKENS_DIR,STYLES_DIR,COLORS,TYPO,SPACING,BASE,COMP,UTIL,A11Y source
    class SD,SASS,POSTCSS,BUILD_SCRIPT build
    class DIST_DIR,DEV_CSS,PROD_CSS,TOKEN_CSS,TAILWIND,MANIFEST assets
    class WCAG,MOTION,HIGH_CONTRAST,SEMANTIC ethical
    class CDN_COPY,EXT_COPY,LOCAL distribution
```

## 🌐 CDN Distribution Flow

The CDN distribution system enables external projects to access dataimago design assets:

```mermaid
graph TB
    %% CDN Distribution Flow
    subgraph "Build System Output"
        BUILD[build_design_system]
        BUILD --> UI_DIST[ui/dist/<br/>Built Assets]
        UI_DIST --> DEV_CSS[dataimago.css<br/>6.1KB Unminified]
        UI_DIST --> PROD_CSS[dataimago.min.css<br/>6.1KB Minified]
        UI_DIST --> TOKENS[tokens.css<br/>1.8KB Variables]
    end

    subgraph "CDN Preparation"
        CDN_DIR[inst/quarto-assets/<br/>CDN Directory]
        SRI[SRI Hash Generation<br/>Security Verification]
        COPY[File Copy Process<br/>ui/dist → inst/quarto-assets]
    end

    subgraph "External Access Methods"
        JSDELIVR[jsDelivr CDN<br/>cdn.jsdelivr.net]
        R_ACCESS[R system.file<br/>Programmatic Access]
        DIRECT[Direct File Access<br/>Package Installation]
    end

    subgraph "Integration Examples"
        HTML[HTML Link Tags<br/>External Websites]
        QUARTO[Quarto _quarto.yml<br/>CSS Configuration]
        R_CODE[R Code<br/>Package Functions]
    end

    subgraph "Usage Patterns"
        PROD_USE[Production Sites<br/>Minified + SRI]
        DEV_USE[Development<br/>Unminified + Comments]
        TOKEN_USE[Custom Styling<br/>Variables Only]
    end

    subgraph "Security & Reliability"
        VERSIONING[Git Tag Versioning<br/>@v0.1.0 References]
        INTEGRITY[Subresource Integrity<br/>sha384- Hashes]
        FALLBACK[Local Fallbacks<br/>CDN Failure Protection]
    end

    %% Flow connections
    DEV_CSS --> COPY
    PROD_CSS --> COPY
    TOKENS --> COPY
    COPY --> CDN_DIR
    
    CDN_DIR --> SRI
    SRI --> JSDELIVR
    CDN_DIR --> R_ACCESS
    CDN_DIR --> DIRECT
    
    JSDELIVR --> HTML
    R_ACCESS --> R_CODE
    DIRECT --> QUARTO
    
    HTML --> PROD_USE
    HTML --> DEV_USE
    QUARTO --> TOKEN_USE
    R_CODE --> DEV_USE
    
    JSDELIVR --> VERSIONING
    VERSIONING --> INTEGRITY
    INTEGRITY --> FALLBACK

    %% Critical path highlighting
    BUILD --> CDN_DIR
    CDN_DIR --> JSDELIVR

    %% Styling
    classDef build fill:#3498db,stroke:#2c3e50,stroke-width:2px,color:#fff
    classDef cdn fill:#e74c3c,stroke:#c0392b,stroke-width:2px,color:#fff
    classDef access fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef integration fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    classDef usage fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef security fill:#1abc9c,stroke:#16a085,stroke-width:2px,color:#fff

    class BUILD,UI_DIST,DEV_CSS,PROD_CSS,TOKENS build
    class CDN_DIR,SRI,COPY cdn
    class JSDELIVR,R_ACCESS,DIRECT access
    class HTML,QUARTO,R_CODE integration
    class PROD_USE,DEV_USE,TOKEN_USE usage
    class VERSIONING,INTEGRITY,FALLBACK security
```

## 🎯 Key Design Principles

### Ethical AI Integration
Every component of the system embeds dataimago's philosophical commitments:

- **WCAG AA Compliance**: All color combinations meet accessibility contrast requirements
- **Reduced Motion Respect**: Animations honor user motion preferences  
- **High Contrast Support**: Alternative color schemes for accessibility needs
- **Semantic Naming**: Design tokens like `ethical-highlight` embed meaning

### R-First Philosophy
The entire system maintains R as the source of truth:

- **R Functions Control Everything**: Node.js tooling wrapped in R functions
- **Intelligent Detection**: System preserves sophisticated build setups
- **Fallback Gracefully**: Creates minimal systems when sophisticated ones don't exist
- **Comprehensive Documentation**: Every R function includes philosophical context

### Multi-Channel Distribution
The same source generates assets for multiple platforms:

- **Quarto Extensions**: Complete styling and functionality packages
- **CDN Distribution**: Direct linking for external projects
- **Next.js Integration**: Tailwind presets for modern web apps
- **R Package Access**: Programmatic file access within R

### Philosophical Integration
Technical documentation embeds ethical context:

- **Hermeneutic Transparency**: Meaning and context in every function
- **Positivistic Rigor**: Technical accuracy and reproducibility
- **Ethical Reflexivity**: Tools for interrogating usage patterns
- **Iterative Design**: Each commit advances emancipatory goals

---

*These diagrams visualize how dataimago embeds AI within culture for emancipatory purposes, rather than embedding culture within AI for domination.*
