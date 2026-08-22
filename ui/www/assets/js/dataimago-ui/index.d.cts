import * as React from 'react';
import * as react_jsx_runtime from 'react/jsx-runtime';
import { LogoId, LogoVariant, AnimationId, NavbarLogoId } from '@dataimago/brand';

type ButtonVariant = 'primary' | 'secondary' | 'ghost';
type ButtonSize = 'sm' | 'md' | 'lg';
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: ButtonVariant;
    size?: ButtonSize;
}
/**
 * Smoke-level `<Button>` for the alpha release of @dataimago/ui.
 *
 * Styling is delegated to semantic CSS variables published by @dataimago/css
 * so that the component stays small and theme-aware.
 * Consumers that want to override visuals can pass their own className.
 */
declare const Button: React.ForwardRefExoticComponent<ButtonProps & React.RefAttributes<HTMLButtonElement>>;

/**
 * <LogoMonogram /> — the dataimago 'a + i' superimposed monogram, transparent
 * background. Glyphs are outlined paths (no font dependency at render time);
 * fill defaults to `currentColor` so the mark inherits from the surrounding
 * text color and respects light/dark theme switches automatically.
 *
 * Symbolism: 'a' (data, agency) superimposed with 'i' (imago, AI) — the
 * fusion is the brand's central idea. See wiki/principles/visual-identity.md
 * (Stage L follow-up) for the full brand-mark rationale.
 *
 * Source artwork: outlined-path SVG from
 * FOUNDATIONS/background/04_dataimago_Content/Design_Assets/logos/
 *   ai_monogram_supreme_1_PATH.svg
 *
 * Usage:
 *   <LogoMonogram size={48} aria-label="dataimago" />
 *   <span style={{ color: 'var(--color-interactive-primary)' }}>
 *     <LogoMonogram size={32} />
 *   </span>
 */
interface LogoMonogramProps extends React.SVGAttributes<SVGSVGElement> {
    /** Render size in px (or any CSS length). Default: 24. Width and height match. */
    size?: number | string;
    /**
     * Accessible name announced by screen readers. Set to `undefined` (or pass
     * `aria-hidden` directly) when the mark is purely decorative.
     */
    title?: string;
}
declare function LogoMonogram({ size, title, ...rest }: LogoMonogramProps): react_jsx_runtime.JSX.Element;

/**
 * <LogoMonogramBg /> — the dataimago 'a + i' monogram with a rounded accent
 * backplate. White letters on the brand-accent role
 * (var(--color-interactive-accent), iteration-2 sky-blue).
 *
 * Use this variant on neutral surfaces where the no-background monogram
 * would lack presence — favicons, app icons, social-media avatars, or any
 * branded chrome where the mark should read as a self-contained badge.
 *
 * Source artwork: outlined-path SVG from
 * FOUNDATIONS/background/04_dataimago_Content/Design_Assets/logos/
 *   ai_monogram_supreme_bg_1_PATH.svg
 *
 * Theming: the background uses var(--color-interactive-accent), which
 * resolves via theme-colors.json's mode-aware role mapping — accent-500
 * (#1f618d) on light surfaces, accent-300 (#3498DB) on dark. The letter
 * fill is hard-set to white; both accent stops have AA-or-better contrast
 * with white letters (light-mode 6.66:1 AA, dark-mode 3.15:1 AA-large for
 * the dot-and-stem heading-size letters used in the monogram). The
 * literal-fallback in this component is light-mode (#1f618d, sky-blue
 * iteration-2) for rare non-CSS-aware contexts. Iteration-1's copper-red
 * fallback (#b54a27) was retired in iteration-2-B.2; see
 * wiki/decisions/iteration-2-blue-accent.md for the rationale.
 *
 * Usage:
 *   <LogoMonogramBg size={64} aria-label="dataimago" />
 */
interface LogoMonogramBgProps extends React.SVGAttributes<SVGSVGElement> {
    /** Render size in px. Default: 32 (favicon-sized). Width and height match. */
    size?: number | string;
    /** Accessible name. Set undefined or pass aria-hidden for decorative use. */
    title?: string;
}
declare function LogoMonogramBg({ size, title, ...rest }: LogoMonogramBgProps): react_jsx_runtime.JSX.Element;

/**
 * <LogoWordmark /> — the full "dataimago" wordmark with the 'ai' overlap.
 * White letters on a rounded accent backplate, themed via
 * var(--color-interactive-accent).
 *
 * Use this variant for primary brand surfaces: site headers, document
 * letterheads, large-format presentations, business materials. For compact
 * contexts (favicons, social avatars) use <LogoMonogramBg /> instead; for
 * inline use within prose use <LogoMonogram /> with currentColor.
 *
 * The wordmark preserves the philosophical idea of the brand: the visible
 * superposition of 'a' (data, human agency) and 'i' (imago, AI) creates a new
 * unified glyph that is neither pure human nor pure artificial — genuine
 * collaboration. See wiki/principles/visual-identity.md (Stage L follow-up).
 *
 * Source artwork: outlined-path SVG from
 * FOUNDATIONS/background/04_dataimago_Content/Design_Assets/logos/
 *   dataimago_supreme_1_PATH.svg
 *
 * Theming: the backplate uses var(--color-interactive-accent), which resolves
 * via theme-colors.json's mode-aware role mapping — accent-500 (#1f618d) on
 * light surfaces, accent-300 (#3498DB) on dark. The literal-fallback in this
 * component is light-mode (#1f618d, sky-blue iteration-2) for the rare cases
 * where the SVG is consumed without CSS-variable resolution (printed PDFs from
 * raw SVG, third-party platforms that strip CSS). Iteration-1's copper-red
 * fallback (#b54a27) was retired in iteration-2-B.2; see
 * wiki/decisions/iteration-2-blue-accent.md for the rationale.
 *
 * Usage:
 *   <LogoWordmark width={240} aria-label="dataimago" />
 *
 * The wordmark's natural aspect ratio is 480x150 (~3.2:1). Pass `width` and
 * height auto-scales, or pass both explicitly.
 */
interface LogoWordmarkProps extends React.SVGAttributes<SVGSVGElement> {
    /** Width in px. Default: 240. Height auto-scales to the 480:150 ratio. */
    width?: number | string;
    /** Accessible name. Set undefined or pass aria-hidden for decorative use. */
    title?: string;
}
declare function LogoWordmark({ width, title, ...rest }: LogoWordmarkProps): react_jsx_runtime.JSX.Element;

interface LogoProps extends React.HTMLAttributes<HTMLSpanElement> {
    /** Mark id, e.g. `dissertation_ai_OVERLAP`. */
    name: LogoId;
    /** PATH (default), CUTOUT, BG, or LETTERS. See @dataimago/brand. */
    variant?: LogoVariant;
    /**
     * Render width (px number or any CSS length). Height scales proportionally
     * via the SVG viewBox. Omit to use the mark's intrinsic size.
     */
    width?: number | string;
}
/**
 * Manifest-driven brand mark from `@dataimago/brand`. Inlines the SVG string so
 * `currentColor` (PATH/LETTERS), the `--color-interactive-accent` badge fill
 * (CUTOUT/BG), and the per-letter interaction classes (`.glyph`, `.logo-*`) all
 * work — an `<img src>` can't receive those interior styles.
 *
 * Color flows from CSS: set `color` (PATH/LETTERS) on this element or an
 * ancestor. Size via `width` (or CSS on the wrapper).
 */
declare function Logo({ name, variant, width, style, ...rest }: LogoProps): react_jsx_runtime.JSX.Element | null;

interface BrandAnimationProps extends React.HTMLAttributes<HTMLSpanElement> {
    /** Animation id, e.g. `dissertation-ai`. See @dataimago/brand animations.json. */
    name: AnimationId;
    /**
     * Render width (px number or any CSS length). Height scales via the SVG
     * viewBox. Omit to use the animation's intrinsic size.
     */
    width?: number | string;
}
/**
 * Decorative brand animation from `@dataimago/brand` (the animation-foundry).
 * Inlines the pure-SMIL SVG string so its interior `<style>` works — an
 * `<img src>` can't receive those styles (same rationale as `<Logo>`).
 *
 * Motion-dignity: decorative brand animation is a distinct category from the
 * 300ms UI-transition ceiling, but it is contractually gated on
 * `prefers-reduced-motion`. When the user prefers reduced motion this renders
 * the static brand mark the animation settles to (its `poster`) via `<Logo>`,
 * so no consumer can ship the motion without the fallback.
 */
declare function BrandAnimation({ name, width, style, ...rest }: BrandAnimationProps): react_jsx_runtime.JSX.Element | null;

interface NavbarLogoProps extends React.HTMLAttributes<HTMLSpanElement> {
    /** Navbar mark id, e.g. `dissertation-ai`. See @dataimago/brand navbar.json. */
    name: NavbarLogoId;
    /**
     * Render width (px number or any CSS length). Height scales via the SVG
     * viewBox. Omit to use the mark's intrinsic size.
     */
    width?: number | string;
}
/**
 * Animated brand mark for an app navbar, from `@dataimago/brand` (the
 * animation-foundry's navbar set). Inlines the self-contained CSS-animated SVG
 * so its interior `<style>` works — an `<img src>` can't receive those styles.
 *
 * Behaviour by mark kind (from the navbar manifest):
 *   - `assemble` (L2: dissertation-ai, rpkg-ai, SGPc-ai): the trailing `a`/`i`
 *     start apart and the `i` slides onto the `a`. Plays once on mount; replays
 *     on pointer-enter via a remount (`replayKey`).
 *   - `shimmer` (L1: dataimago-ai): the monogram is always superimposed; an
 *     accent shimmer sweeps on `:hover` from the SVG's own CSS (no JS trigger).
 *
 * Motion-dignity: the embedded CSS animation is <= 300ms and gated on
 * `@media (prefers-reduced-motion: no-preference)`. When the user prefers
 * reduced motion this renders the static settled mark (the manifest `poster`,
 * the superimposed monogram) via `<Logo>` — so no consumer can ship the motion
 * without the fallback.
 */
declare function NavbarLogo({ name, width, style, ...rest }: NavbarLogoProps): react_jsx_runtime.JSX.Element | null;

export { BrandAnimation, type BrandAnimationProps, Button, type ButtonProps, type ButtonSize, type ButtonVariant, Logo, LogoMonogram, LogoMonogramBg, type LogoMonogramBgProps, type LogoMonogramProps, type LogoProps, LogoWordmark, type LogoWordmarkProps, NavbarLogo, type NavbarLogoProps };
