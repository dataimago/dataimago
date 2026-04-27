import * as React from 'react';

type ButtonVariant = 'primary' | 'secondary' | 'ghost';
type ButtonSize = 'sm' | 'md' | 'lg';
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: ButtonVariant;
    size?: ButtonSize;
}
/**
 * Smoke-level `<Button>` for the alpha release of @dataimago/ui.
 *
 * Styling is delegated to the CSS classes `.btn`, `.btn-<variant>`, `.btn-<size>`
 * published by @dataimago/css so that the component stays small and theme-aware.
 * Consumers that want to override visuals can pass their own className.
 */
declare const Button: React.ForwardRefExoticComponent<ButtonProps & React.RefAttributes<HTMLButtonElement>>;

export { Button, type ButtonProps, type ButtonSize, type ButtonVariant };
