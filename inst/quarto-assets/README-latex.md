# dataimago.sty - LaTeX Design System Package

> **Version:** 0.1.0  
> **Date:** October 19, 2025  
> **License:** MIT  
> **Location:** `dataimago-design/src/latex/` (design system submodule)

A unified LaTeX package providing consistent typography, colors, and layout for PDF documents aligned with the **dataimago design system**.

## 🎯 Design System Integration

This LaTeX package is part of the **dataimago design system** and is distributed automatically to all consumer repositories via the build system:

**Source Location:** `ui/src/dataimago-design/src/latex/` (git submodule)

**Distribution Channels:**
1. **CDN Distribution** - `inst/quarto-assets/` (jsDelivr via GitHub)
2. **Quarto Extension** - `ui/www/_extensions/dataimago/ai-native/assets/latex/`
3. **Website Assets** - `ui/www/assets/latex/` (local development)
4. **Documentation** - `docs/assets/latex/` (GitHub Pages)

**Automated Build:** Assets are distributed via `build_design_system()` in R package

**Consumer Repositories:** Available in dataimago-rpkg, sgpFlow, HelloWorld, and all future dataimago projects

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Package Structure](#package-structure)
- [Customization](#customization)
- [Integration with Design System](#integration-with-design-system)
- [Troubleshooting](#troubleshooting)
- [Development Guide](#development-guide)
- [Version History](#version-history)

---

## Overview

`dataimago.sty` consolidates the dataimago design system for LaTeX/PDF documents. It replaces five separate `.tex` style files with a single, portable, well-documented package.

**Key Benefits:**
- ✅ **Portable** - Uses system fonts (no absolute paths)
- ✅ **Modular** - Conditional loading based on document class
- ✅ **Consistent** - Aligned with dataimago design tokens
- ✅ **Maintainable** - Single file, comprehensive documentation
- ✅ **Flexible** - Supports both memoir and article classes

**Design System Alignment:**
- Typography: Noto Sans (body), Josefin Sans (headings), Noto Sans Math (equations)
- Colors: OKLCH-based surface, content, border, and brand tokens
- Layout: Custom memoir styles with dataimago aesthetic

---

## Requirements

### LaTeX Engine
- **XeLaTeX** or **LuaLaTeX** (required for `fontspec` and `unicode-math`)
- Not compatible with pdfLaTeX

### System Fonts
All fonts must be installed as system fonts (accessible to fontspec by name):

1. **Noto Sans** (body text)
   - Install all weights/styles
   - Available at: [Google Fonts - Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans)

2. **Noto Sans Mono** (code/monospace)
   - Available at: [Google Fonts - Noto Sans Mono](https://fonts.google.com/noto/specimen/Noto+Sans+Mono)

3. **Noto Sans Math** (mathematical equations)
   - Available at: [GitHub - Noto Math](https://github.com/notofonts/math)

4. **Josefin Sans** (headings/display)
   - Required weights: Thin (200), Light (300), Regular (400), SemiBold (600), Bold (700)
   - Available at: [Google Fonts - Josefin Sans](https://fonts.google.com/specimen/Josefin+Sans)

**Note:** On macOS, install fonts via Font Book. On Linux, install to `~/.fonts/` or system font directory.

### LaTeX Packages
The following packages are automatically loaded by `dataimago.sty`:
- `fontspec`, `unicode-math`
- `xcolor` (with svgnames)
- `graphicx`, `url`, `rotating`, `bm`, `amsmath`, `amsfonts`, `amssymb`, `indentfirst`, `lscape`
- `caption`, `tcolorbox`, `enumitem`
- **Memoir class only:** `epigraph`, `tabularx`
- **Article class only:** `sectsty`, `titling`

### Document Classes
- **memoir** (recommended) - Full feature set including custom chapter styles, page layouts, front matter
- **article** - Basic typography and color support only

---

## Installation

### Method 1: Local Directory (Recommended for Projects)

1. Copy `dataimago.sty` to your project's style directory:
   ```
   your-project/
   ├── main.tex
   └── styles/
       └── dataimago.sty
   ```

2. Load in your LaTeX preamble:
   ```latex
   \makeatletter
   \input{styles/dataimago.sty}
   \makeatother
   ```

### Method 2: TEXMF Tree (System-wide)

1. Find your local TEXMF directory:
   ```bash
   kpsewhich -var-value=TEXMFHOME
   # Usually: ~/texmf (Linux/macOS) or %USERPROFILE%\texmf (Windows)
   ```

2. Copy to the appropriate location:
   ```bash
   mkdir -p ~/texmf/tex/latex/dataimago
   cp dataimago.sty ~/texmf/tex/latex/dataimago/
   texhash ~/texmf
   ```

3. Use with standard `\usepackage`:
   ```latex
   \usepackage{dataimago}
   ```

### Method 3: Quarto Integration

In `_quarto.yml`, add to `include-in-header`:

```yaml
format:
  pdf:
    include-in-header:
      - text: |
          \makeatletter
          \input{styles/dataimago.sty}
          \makeatother
```

**Note:** `\makeatletter` is required when loading `.sty` files via `\input` (not needed with `\usepackage`).

---

## Usage

### Basic Example (Memoir Class)

```latex
\documentclass[11pt,oneside]{memoir}

% Load dataimago package
\makeatletter
\input{styles/dataimago.sty}
\makeatother

% Document metadata
\title{Your Document Title}
\subtitle{An Optional Subtitle}  % Memoir only
\author{Your Name}
\date{\today}

\begin{document}

\maketitle

\chapter{Introduction}
Your content here...

\section{A Section}
More content...

\subsection{A Subsection}
Even more content...

\end{document}
```

### Basic Example (Article Class)

```latex
\documentclass[11pt]{article}

\makeatletter
\input{styles/dataimago.sty}
\makeatother

\title{Your Document Title}
\author{Your Name}
\date{\today}

\begin{document}

\maketitle

\section{Introduction}
Your content here...

\end{document}
```

### Using Custom Boxes

```latex
% Theorem box
\begin{theorembox}{Theorem 1: Fundamental Result}
Let $f: X \to Y$ be a continuous function...
\end{theorembox}

% Definition box
\begin{definitionbox}{Definition 1: Copula}
A copula is a multivariate cumulative distribution function...
\end{definitionbox}

% Proof environment
\begin{proof}
We proceed by induction...
\end{proof}
```

---

## Features

### 1. Typography System

**Body Font Stack:**
- Primary: Noto Sans (body text, captions)
- Monospace: Noto Sans Mono (code samples)
- Math: Noto Sans Math (equations with OpenType MATH support)

**Display Font Stack:**
- Josefin Sans with hierarchical weights:
  - **Bold (700)** - Document title, chapter titles
  - **SemiBold (600)** - Subtitles
  - **Medium (500)** - Sections (falls back to Regular)
  - **Regular (400)** - Subsections
  - **Light (300)** - Subsubsections
  - **Thin (200)** - Reserved for future use (captions, labels)

**Font Commands:**
```latex
\HeadingFont           % Default (Bold)
\HeadingFontBold       % Alias for \HeadingFont
\HeadingFontSemiBold   % For subtitles
\HeadingFontMedium     % For sections
\HeadingFontRegular    % For subsections
\HeadingFontLight      % For subsubsections
\HeadingFontExtraLight % Thin weight
```

### 2. Color Tokens

All colors are defined using dataimago design system tokens:

**Surface Colors (Light Theme):**
```latex
\definecolor{SurfacePage}{RGB}{237, 237, 235}       % Page background
\definecolor{SurfaceCode}{RGB}{225, 225, 223}       % Code blocks
\definecolor{SurfaceElevated}{RGB}{237, 237, 235}   % Elevated surfaces
```

**Content Colors:**
```latex
\definecolor{ContentPrimary}{RGB}{20, 20, 16}       % Primary text
\definecolor{ContentSecondary}{HTML}{7c7c7c}        % Secondary text
```

**Border Colors:**
```latex
\definecolor{BorderCode}{RGB}{220, 220, 218}        % Code borders
\definecolor{BorderModerate}{RGB}{51, 51, 46}       % Moderate borders
```

**Brand Colors:**
```latex
\definecolor{DataimagoPrimary}{HTML}{3498DB}        % Primary brand blue
\definecolor{DataimagoAccent}{HTML}{ff69b4}         % Accent pink
\definecolor{DataimagoEthical}{HTML}{E74C3C}        % Ethical red
```

**Functional Colors:**
```latex
\definecolor{InfoColor}{HTML}{3498DB}               % Information
\definecolor{WarningColor}{HTML}{F39C12}            % Warnings
\definecolor{ErrorColor}{HTML}{E74C3C}              % Errors
\definecolor{SuccessColor}{HTML}{27AE60}            % Success states
```

### 3. Memoir-Specific Features

**Custom Page Styles:**
- `dataimago` - Main page style with headers and footers
- `plain` - Chapter opening pages (centered page numbers)
- `frontmatter` - Front matter pages (no headers)

**Custom Chapter Style:**
- `dataimago-ell` - Right-aligned chapter numbers and titles with elegant horizontal rule

**Front Matter Commands:**
```latex
\dataimagoLogo        % AI monogram logo
\ccbyLogo             % CC-BY-SA license badge
\version{v1.0.0}      % Set version number
\maketitle            % Custom right-justified title page
```

**Section Numbering:**
- Chapters: 1, 2, 3...
- Sections: 1.1, 1.2, 1.3...
- Subsections: 1.1.1, 1.1.2...
- Subsubsections: 1.1.1.1, 1.1.1.2...

### 4. Custom Environments

**Theorem Box:**
```latex
\begin{theorembox}[options]{Title}
  Content
\end{theorembox}
```

**Definition Box:**
```latex
\begin{definitionbox}[options]{Title}
  Content
\end{definitionbox}
```

**Proof Environment:**
```latex
\begin{proof}
  Proof content
\end{proof}
```

### 5. Custom Commands

```latex
\R            % Formats "R" for R language
\sgpFlow      % Formats "sgpFlow" package name
\sref{label}  % Section reference with § symbol
```

---

## Package Structure

The package is organized into seven sections:

### Section 1: Typography - Fonts (Lines 75-177)
- Font family definitions (Noto Sans, Josefin Sans)
- Weight variants and scaling
- Conditional application for memoir vs article

### Section 2: Colors - Design Tokens (Lines 179-247)
- Surface, content, border, brand, and functional colors
- Page background and figure border settings

### Section 3: Memoir Class Configuration (Lines 249-426)
- Page styles and headers/footers
- Chapter and section formatting
- TOC customization
- Custom chapter style (dataimago-ell)

### Section 4: Custom Boxes and Environments (Lines 428-490)
- Theorem and definition boxes
- Proof environment
- Abstract suppression for Quarto

### Section 5: Caption and List Formatting (Lines 492-518)
- Caption styling
- Enumerate and itemize formatting

### Section 6: Custom Commands (Lines 520-532)
- Software/package name commands
- Section reference utilities
- Abstract name customization

### Section 7: Front Matter Commands (Lines 534-625)
- Logo commands (dataimago, CC-BY-SA)
- Version command
- Custom title page (memoir only)

---

## Customization

### Changing Colors

To override default colors, redefine them after loading the package:

```latex
\makeatletter
\input{styles/dataimago.sty}
\makeatother

% Override brand primary color
\definecolor{DataimagoPrimary}{HTML}{FF5733}
```

### Adjusting Typography

To change heading font scaling or letter spacing:

```latex
% After loading dataimago.sty
\renewcommand{\HeadingFont}{%
  \fontspec[Scale=1.1, LetterSpace=1.0]{Josefin Sans}%
}
```

### Custom Page Layout (Memoir)

To adjust page margins:

```latex
\makeatletter
\input{styles/dataimago.sty}
\makeatother

% Custom margins
\settypeblocksize{8.5in}{6.0in}{*}
\setlrmargins{1.25in}{*}{1}
\checkandfixthelayout
```

### Adding New Box Styles

```latex
% After loading dataimago.sty
\newtcolorbox{examplebox}[2][]{
  enhanced,
  breakable,
  colback=SurfaceCode,
  colframe=DataimagoPrimary,
  boxrule=1pt,
  arc=4pt,
  title={#2},
  fonttitle=\HeadingFont\bfseries,
  #1
}
```

---

## Integration with Design System

`dataimago.sty` is designed to integrate with the broader **dataimago design system**, which includes:

1. **Node.js/TypeScript Design System** (`dataimago-design`)
   - Token definitions (colors, typography, spacing)
   - Sass/SCSS variables
   - CSS custom properties

2. **R Package** (`dataimago` R package)
   - HTML/Quarto themes
   - RMarkdown templates
   - Data visualization themes

3. **LaTeX Package** (`dataimago.sty`) ← *This file*
   - PDF typography and styling
   - Memoir/article class support

### Token Alignment

All colors in `dataimago.sty` are annotated with their corresponding design token names:

```latex
% Token: color.surface.page.light = rgb(237, 237, 235)
\definecolor{SurfacePage}{RGB}{237, 237, 235}
```

This ensures consistency when updating the design system. To update tokens:

1. Update the token value in the design system source
2. Find the corresponding color definition in `dataimago.sty`
3. Update the RGB/HTML value
4. Verify the token comment is accurate

### Future Integration

When `dataimago.sty` is integrated into the R package distribution:

```r
# R function to get dataimago.sty path
dataimago::get_dataimago_sty_path()

# Copy dataimago.sty to project
dataimago::copy_dataimago_sty("path/to/project/styles/")
```

---

## Troubleshooting

### Font Not Found Errors

**Error:** `Package fontspec Error: The font "Noto Sans" cannot be found`

**Solution:**
1. Verify fonts are installed:
   ```bash
   # macOS
   fc-list | grep -i "noto sans"
   fc-list | grep -i "josefin"
   
   # Or check Font Book app
   ```

2. Install missing fonts:
   - Download from Google Fonts
   - Install via Font Book (macOS) or font manager
   - Restart Terminal/IDE after installation

3. Test font availability:
   ```latex
   \documentclass{article}
   \usepackage{fontspec}
   
   \IfFontExistsTF{Noto Sans}{
     \typeout{SUCCESS: Noto Sans found}
   }{
     \typeout{ERROR: Noto Sans not found}
   }
   
   \begin{document}
   Test
   \end{document}
   ```

### Compilation Errors with \input

**Error:** `You can't use \spacefactor in vertical mode`

**Solution:** Wrap `\input` with `\makeatletter`:

```latex
% WRONG:
\input{styles/dataimago.sty}

% CORRECT:
\makeatletter
\input{styles/dataimago.sty}
\makeatother
```

Or use system-wide installation with `\usepackage{dataimago}` (no wrapper needed).

### Missing Memoir Features in Article Class

**Issue:** Custom chapter styles, title page, or front matter commands not working.

**Solution:** These features are memoir-specific. Either:
1. Switch to memoir document class
2. Use basic features only with article class

### Incompatible with pdfLaTeX

**Error:** Package fontspec requires XeLaTeX or LuaLaTeX

**Solution:** Use XeLaTeX or LuaLaTeX instead:
```bash
xelatex document.tex
# or
lualatex document.tex
```

In Quarto:
```yaml
format:
  pdf:
    pdf-engine: xelatex  # or lualatex
```

---

## Development Guide

### File Organization

When modifying `dataimago.sty`, maintain the seven-section structure:

1. **Typography** - Font definitions and variants
2. **Colors** - Design token definitions
3. **Memoir Config** - Page styles, chapters, sections (conditional)
4. **Boxes** - Custom environments
5. **Captions/Lists** - Formatting
6. **Commands** - Utility commands
7. **Front Matter** - Title page, logos (conditional)

### Adding New Features

**To add a new color:**
```latex
% In Section 2: COLORS
% Token: color.category.name.variant = value
\definecolor{NewColorName}{RGB}{r, g, b}
```

**To add a new font variant:**
```latex
% In Section 1: TYPOGRAPHY
\newfontfamily\NewFontCommand[
  Scale=MatchLowercase,
  LetterSpace=0.5,
  BoldFont=Josefin Sans
]{Josefin Sans SemiBold}
```

**To add a new box environment:**
```latex
% In Section 4: CUSTOM BOXES
\newtcolorbox{newbox}[2][]{
  enhanced,
  breakable,
  colback=SurfacePage,
  colframe=BorderModerate,
  title={#2},
  fonttitle=\HeadingFont\bfseries,
  #1
}
```

### Testing Changes

1. **Create test document:**
   ```latex
   \documentclass{memoir}
   \makeatletter
   \input{dataimago.sty}
   \makeatother
   
   \begin{document}
   % Test your changes
   \end{document}
   ```

2. **Compile with XeLaTeX:**
   ```bash
   xelatex test.tex
   ```

3. **Check for errors:**
   - Font loading issues
   - Color definitions
   - Conditional logic (memoir vs article)

4. **Visual inspection:**
   - Typography hierarchy
   - Color accuracy
   - Layout consistency

### Version Updates

When releasing a new version:

1. Update version number (lines 10, 33):
   ```latex
   %%% Version: 0.2.0
   %%% Date: 2025-MM-DD
   
   \ProvidesPackage{dataimago}[2025/MM/DD v0.2.0 dataimago Design System]
   ```

2. Update typeout message (line 38):
   ```latex
   \typeout{dataimago.sty v0.2.0 - dataimago Design System for LaTeX}
   ```

3. Document changes in this README under [Version History](#version-history)

4. Update token comments if design system tokens change

### Code Style Guidelines

- **Indentation:** 2 spaces per level
- **Line length:** Max 100 characters (comments can exceed)
- **Comments:** Use `%%%` for section headers, `%%` for subsection headers, `%` for inline
- **Token references:** Always include token name and value in comments
- **Conditional blocks:** Document which document class features apply to

---

## Version History

### v0.1.0 (2025-10-19)
- **Initial release**
- Unified package consolidating 5 separate `.tex` files:
  - `pdf-fonts-noto.tex` → Section 1 (Typography)
  - `paper-custom-boxes.tex` → Section 4 (Boxes)
  - `memoir-book-setup.tex` → Section 3 (Memoir config)
  - `memoir-chapter-styles.tex` → Section 3 (Chapter styles)
  - `memoir-section-styles.tex` → Section 3 (Section styles)
- System font support (no absolute paths)
- dataimago design token integration
- Conditional loading for memoir vs article classes
- Custom theorem/definition boxes
- Custom memoir chapter style (dataimago-ell)
- Comprehensive documentation

---

## Contributing

To contribute improvements to `dataimago.sty`:

1. **Test thoroughly** with both memoir and article classes
2. **Document changes** with inline comments and token references
3. **Update this README** with new features or breaking changes
4. **Maintain compatibility** with existing documents
5. **Follow code style guidelines** for consistency

---

## License

MIT License

Copyright (c) 2025 dataimago

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Contact

For questions, issues, or contributions:
- **Website:** [dataimago.ai](https://dataimago.ai)
- **GitHub:** [dataimago repositories](https://github.com/dataimago)

---

**End of README**

