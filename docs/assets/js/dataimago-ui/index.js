// src/Button.tsx
import * as React from "react";
import { jsx } from "react/jsx-runtime";
var variantClasses = {
  primary: "btn-primary",
  secondary: "btn-secondary",
  ghost: "btn-ghost"
};
var sizeClasses = {
  sm: "btn-sm",
  md: "btn-md",
  lg: "btn-lg"
};
var Button = React.forwardRef(
  function Button2({ variant = "primary", size = "md", className = "", type, children, ...rest }, ref) {
    const classes = [
      "btn",
      variantClasses[variant],
      sizeClasses[size],
      className
    ].filter(Boolean).join(" ");
    return /* @__PURE__ */ jsx(
      "button",
      {
        ref,
        type: type ?? "button",
        className: classes,
        ...rest,
        children
      }
    );
  }
);
export {
  Button
};
//# sourceMappingURL=index.js.map