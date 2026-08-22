'use client';
"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.ts
var index_exports = {};
__export(index_exports, {
  BrandAnimation: () => BrandAnimation,
  Button: () => Button,
  Logo: () => Logo,
  LogoMonogram: () => LogoMonogram,
  LogoMonogramBg: () => LogoMonogramBg,
  LogoWordmark: () => LogoWordmark,
  NavbarLogo: () => NavbarLogo
});
module.exports = __toCommonJS(index_exports);

// src/Button.tsx
var React = __toESM(require("react"), 1);
var import_jsx_runtime = require("react/jsx-runtime");
var variantClasses = {
  primary: "di-ui-button--primary",
  secondary: "di-ui-button--secondary",
  ghost: "di-ui-button--ghost"
};
var sizeClasses = {
  sm: "di-ui-button--sm",
  md: "di-ui-button--md",
  lg: "di-ui-button--lg"
};
var baseStyle = {
  alignItems: "center",
  borderRadius: "var(--radius-md, 0.5rem)",
  borderStyle: "solid",
  borderWidth: "1px",
  cursor: "pointer",
  display: "inline-flex",
  fontFamily: "var(--font-family-sans, system-ui, sans-serif)",
  fontWeight: "var(--font-weight-medium, 500)",
  gap: "var(--spacing-sm, 0.5rem)",
  justifyContent: "center",
  textDecoration: "none",
  transition: "background-color 150ms ease, border-color 150ms ease, color 150ms ease"
};
var variantStyles = {
  primary: {
    backgroundColor: "var(--color-interactive-primary)",
    borderColor: "var(--color-interactive-primary)",
    color: "var(--color-content-inverse)"
  },
  secondary: {
    backgroundColor: "var(--color-surface-elevated)",
    borderColor: "var(--color-border-moderate)",
    color: "var(--color-content-primary)"
  },
  ghost: {
    backgroundColor: "transparent",
    borderColor: "transparent",
    color: "var(--color-content-secondary)"
  }
};
var sizeStyles = {
  sm: {
    fontSize: "var(--font-size-small, 0.875rem)",
    minHeight: "2rem",
    padding: "0.375rem 0.75rem"
  },
  md: {
    fontSize: "var(--font-size-base, 1rem)",
    minHeight: "2.5rem",
    padding: "0.625rem 1rem"
  },
  lg: {
    fontSize: "var(--font-size-readable, 1.125rem)",
    minHeight: "3rem",
    padding: "0.75rem 1.25rem"
  }
};
var Button = React.forwardRef(
  function Button2({ variant = "primary", size = "md", className = "", style, type, children, ...rest }, ref) {
    const classes = [
      "di-ui-button",
      variantClasses[variant],
      sizeClasses[size],
      className
    ].filter(Boolean).join(" ");
    return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
      "button",
      {
        ref,
        type: type ?? "button",
        className: classes,
        style: {
          ...baseStyle,
          ...variantStyles[variant],
          ...sizeStyles[size],
          ...style
        },
        ...rest,
        children
      }
    );
  }
);

// src/brand/LogoMonogram.tsx
var import_jsx_runtime2 = require("react/jsx-runtime");
function LogoMonogram({
  size = 24,
  title = "dataimago",
  ...rest
}) {
  const a11yProps = title ? { role: "img" } : { "aria-hidden": true };
  return /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(
    "svg",
    {
      xmlns: "http://www.w3.org/2000/svg",
      viewBox: "0 0 480 480",
      width: size,
      height: size,
      fill: "currentColor",
      "aria-label": title,
      ...a11yProps,
      ...rest,
      children: [
        title ? /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("title", { children: title }) : null,
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("path", { d: "m 337.3457,97.089844 q 0,8.906246 -6.49414,15.400386 -6.49414,6.49415 -15.58594,6.49415 -9.09179,0 -15.77148,-6.67969 Q 293,105.25391 293,96.162109 q 0,-9.091797 6.30859,-15.40039 6.49414,-6.494141 15.40039,-6.494141 9.0918,0 15.77149,6.865234 6.86523,6.679688 6.86523,15.957032 z M 324.54297,180.21484 303.01953,355 h -41.00586 l 21.52344,-174.78516 z" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("path", { d: "M 325.70312,176.01562 303.04687,360 h -43.16406 l 2.53906,-19.92188 Q 234.6875,364.29687 205,364.29687 q -36.52344,0 -59.57031,-24.80468 -23.04688,-24.80469 -23.04688,-64.25782 0,-45.50781 26.36719,-74.60937 26.75781,-29.10156 68.55469,-29.10156 19.72656,0 33.59375,6.44531 14.0625,6.44531 28.71093,22.26562 l 2.92969,-24.21875 z m -52.53906,86.71875 q 0,-24.41406 -14.0625,-39.64843 -14.0625,-15.42969 -36.32812,-15.42969 -24.21875,0 -40.625,18.94531 -16.40625,19.14063 -16.40625,46.875 0,24.21875 13.67187,39.64844 13.67188,15.42969 35.15625,15.42969 23.82813,0 41.21094,-19.33594 17.38281,-19.72656 17.38281,-46.48438 z" })
      ]
    }
  );
}

// src/brand/LogoMonogramBg.tsx
var import_jsx_runtime3 = require("react/jsx-runtime");
function LogoMonogramBg({
  size = 32,
  title = "dataimago",
  ...rest
}) {
  const a11yProps = title ? { role: "img" } : { "aria-hidden": true };
  return /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)(
    "svg",
    {
      xmlns: "http://www.w3.org/2000/svg",
      viewBox: "0 0 480 480",
      width: size,
      height: size,
      "aria-label": title,
      ...a11yProps,
      ...rest,
      children: [
        title ? /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("title", { children: title }) : null,
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(
          "rect",
          {
            width: "100%",
            height: "100%",
            rx: "40",
            ry: "40",
            fill: "var(--color-interactive-accent, #1f618d)"
          }
        ),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(
          "path",
          {
            fill: "#ffffff",
            d: "M 325.70312,176.01562 303.04687,360 h -43.16406 l 2.53906,-19.92188 Q 234.6875,364.29687 205,364.29687 q -36.52344,0 -59.57031,-24.80468 -23.04688,-24.80469 -23.04688,-64.25782 0,-45.50781 26.36719,-74.60937 26.75781,-29.10156 68.55469,-29.10156 19.72656,0 33.59375,6.44531 14.0625,6.44531 28.71093,22.26562 l 2.92969,-24.21875 z m -52.53906,86.71875 q 0,-24.41406 -14.0625,-39.64843 -14.0625,-15.42969 -36.32812,-15.42969 -24.21875,0 -40.625,18.94531 -16.40625,19.14063 -16.40625,46.875 0,24.21875 13.67187,39.64844 13.67188,15.42969 35.15625,15.42969 23.82813,0 41.21094,-19.33594 17.38281,-19.72656 17.38281,-46.48438 z"
          }
        ),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(
          "path",
          {
            fill: "#ffffff",
            d: "m 337.3457,97.089844 q 0,8.906246 -6.49414,15.400386 -6.49414,6.49415 -15.58594,6.49415 -9.09179,0 -15.77148,-6.67969 Q 293,105.25391 293,96.162109 q 0,-9.091797 6.30859,-15.40039 6.49414,-6.494141 15.40039,-6.494141 9.0918,0 15.77149,6.865234 6.86523,6.679688 6.86523,15.957032 z M 324.54297,180.21484 303.01953,355 h -41.00586 l 21.52344,-174.78516 z"
          }
        )
      ]
    }
  );
}

// src/brand/LogoWordmark.tsx
var import_jsx_runtime4 = require("react/jsx-runtime");
function LogoWordmark({
  width = 240,
  title = "dataimago",
  ...rest
}) {
  const a11yProps = title ? { role: "img" } : { "aria-hidden": true };
  return /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(
    "svg",
    {
      xmlns: "http://www.w3.org/2000/svg",
      viewBox: "0 0 480 150",
      width,
      "aria-label": title,
      ...a11yProps,
      ...rest,
      children: [
        title ? /* @__PURE__ */ (0, import_jsx_runtime4.jsx)("title", { children: title }) : null,
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(
          "rect",
          {
            width: "100%",
            height: "100%",
            rx: "5",
            ry: "5",
            fill: "var(--color-interactive-accent, #1f618d)"
          }
        ),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(
          "path",
          {
            fill: "#ffffff",
            d: "M 104.80469,35.621094 97.492187,95 h -7.734375 l 0.421875,-3.550781 q -2.882812,2.566406 -4.992187,3.480468 -2.074219,0.84375 -5.132813,0.84375 -6.960937,0 -11.390625,-4.605468 -4.429687,-4.640625 -4.429687,-11.953125 0,-7.804688 4.851562,-12.972657 4.851563,-5.167968 12.199219,-5.167968 3.761719,0 6.328125,1.300781 2.671875,1.335937 5.589844,4.535156 L 97.035156,35.621094 Z M 92.007812,77 q 0,-4.21875 -2.601562,-6.820313 -2.601563,-2.601562 -6.820313,-2.601562 -4.570312,0 -7.558593,3.410156 -2.988282,3.410156 -2.988282,8.613281 0,4.394532 2.566407,7.066407 2.566406,2.636718 6.820312,2.636718 4.429688,0 7.488281,-3.585937 Q 92.007812,82.203125 92.007812,77 Z M 145.51562,61.882812 141.4375,95 h -7.76953 l 0.45703,-3.585938 q -4.99219,4.359375 -10.33594,4.359375 -6.57422,0 -10.72265,-4.464843 -4.14844,-4.464844 -4.14844,-11.566407 0,-8.191406 4.74609,-13.429687 4.81641,-5.238281 12.33985,-5.238281 3.55078,0 6.04687,1.160156 2.53125,1.160156 5.16797,4.007812 l 0.52734,-4.359375 z m -9.45703,15.609375 q 0,-4.394531 -2.53125,-7.136718 -2.53125,-2.777344 -6.53906,-2.777344 -4.35937,0 -7.3125,3.410156 -2.95312,3.445313 -2.95312,8.4375 0,4.359375 2.46093,7.136719 2.46094,2.777344 6.32813,2.777344 4.28906,0 7.41797,-3.480469 3.1289,-3.550781 3.1289,-8.367188 z M 163.79687,69.089844 160.59766,95 h -7.76954 l 3.19922,-25.910156 h -4.39453 l 0.87891,-7.207032 h 4.39453 l 1.89844,-15.363281 h 7.76953 l -1.89844,15.363281 h 7.17188 l -0.87891,7.207032 z M 211.29297,61.882812 207.21484,95 h -7.76953 l 0.45703,-3.585938 q -4.99218,4.359375 -10.33593,4.359375 -6.57422,0 -10.72266,-4.464843 -4.14844,-4.464844 -4.14844,-11.566407 0,-8.191406 4.7461,-13.429687 4.8164,-5.238281 12.33984,-5.238281 3.55078,0 6.04687,1.160156 2.53125,1.160156 5.16797,4.007812 l 0.52735,-4.359375 z m -9.45703,15.609375 q 0,-4.394531 -2.53125,-7.136718 -2.53125,-2.777344 -6.53907,-2.777344 -4.35937,0 -7.3125,3.410156 -2.95312,3.445313 -2.95312,8.4375 0,4.359375 2.46094,7.136719 2.46093,2.777344 6.32812,2.777344 4.28906,0 7.41797,-3.480469 3.12891,-3.550781 3.12891,-8.367188 z"
          }
        ),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(
          "path",
          {
            fill: "#ffffff",
            d: "m 213.40234,46.132812 q 0,1.6875 -1.23047,2.917969 -1.23046,1.230469 -2.95312,1.230469 -1.72266,0 -2.98828,-1.265625 Q 205,47.679687 205,45.957031 q 0,-1.722656 1.19531,-2.917969 1.23047,-1.230468 2.91797,-1.230468 1.72266,0 2.98828,1.300781 1.30078,1.265625 1.30078,3.023437 z m -2.42578,15.75 L 206.89844,95 h -7.76953 l 4.07812,-33.117188 z m 18.87891,0 -0.35156,3.09375 q 3.9375,-3.9375 9.10546,-3.9375 3.12891,0 4.81641,1.160157 1.6875,1.089843 3.02344,4.113281 4.92187,-5.238281 10.61719,-5.238281 9.84375,0 9.84375,9.035156 0,0.914062 -0.17579,2.566406 -0.14062,1.652344 -0.42187,4.078125 L 264.0625,95 h -7.76953 l 2.39062,-19.160156 Q 259,73.167969 259,71.902344 q 0,-4.324219 -4.35938,-4.324219 -1.72265,0 -2.98828,0.527344 -1.26562,0.492187 -2.17968,1.582031 -0.87891,1.054687 -1.47657,2.777344 -0.5625,1.6875 -0.8789,4.042968 L 244.86719,95 h -7.76953 l 2.42578,-19.652344 q 0.3164,-2.671875 0.3164,-3.65625 0,-4.113281 -4.46484,-4.113281 -6.46875,0 -7.55859,8.964844 L 225.53125,95 h -7.76953 l 4.07812,-33.117188 z m 81.63281,0 L 307.41016,95 h -7.76954 l 0.45704,-3.585938 q -4.99219,4.359375 -10.33594,4.359375 -6.57422,0 -10.72266,-4.464843 -4.14844,-4.464844 -4.14844,-11.566407 0,-8.191406 4.7461,-13.429687 4.8164,-5.238281 12.33984,-5.238281 3.55078,0 6.04688,1.160156 2.53125,1.160156 5.16797,4.007812 l 0.52734,-4.359375 z m -9.45703,15.609375 q 0,-4.394531 -2.53125,-7.136718 -2.53125,-2.777344 -6.53906,-2.777344 -4.35938,0 -7.3125,3.410156 -2.95313,3.445313 -2.95313,8.4375 0,4.359375 2.46094,7.136719 2.46094,2.777344 6.32812,2.777344 4.28907,0 7.41797,-3.480469 3.12891,-3.550781 3.12891,-8.367188 z m 53.57812,-15.609375 -4.07812,33.363282 q -0.38672,2.988281 -0.87891,5.203126 -0.45703,2.21484 -1.05468,3.72656 -1.23047,3.09375 -3.65625,5.3086 -4.71094,4.21875 -12.23438,4.21875 -7.76953,0 -12.58594,-4.07813 -2.46093,-2.03906 -3.44531,-4.64062 -0.98437,-2.39063 -0.98437,-6.714849 h 7.52343 q 0.28125,4.675779 2.39063,6.785159 2.10937,2.14453 6.53906,2.14453 4.78125,0 7.27734,-2.56641 2.4961,-2.53125 3.16407,-8.085935 l 0.5625,-4.535156 q -4.92188,3.761718 -10.33594,3.761718 -6.75,0 -11.14453,-4.605468 -4.39453,-4.710938 -4.39453,-11.742188 0,-7.910156 5.09765,-13.113281 5.13282,-5.238281 12.83203,-5.238281 3.69141,0 5.97657,1.089843 2.49609,1.054688 5.16797,3.832032 l 0.49218,-4.113282 z m -8.92968,15.714844 q 0,-4.5 -2.74219,-7.242187 -2.74219,-2.777344 -7.17188,-2.777344 -4.60546,0 -7.66406,3.375 -3.02344,3.339844 -3.02344,8.402344 0,4.429687 2.60157,7.242187 2.63672,2.707031 6.96093,2.707031 4.81641,0 7.91016,-3.304687 3.12891,-3.339844 3.12891,-8.402344 z m 52.3125,0.527344 q 0,7.59375 -5.27344,12.761719 -5.23828,5.167968 -12.9375,5.167968 -8.05078,0 -13.14844,-4.886718 Q 362.5,86.246094 362.5,78.722656 q 0,-7.699219 5.30859,-12.796875 5.34375,-5.132812 13.35938,-5.132812 7.875,0 12.83203,4.851562 4.99219,4.78125 4.99219,12.480469 z m -7.83985,-0.386719 q 0,-4.78125 -2.77734,-7.558594 -2.77734,-2.882812 -7.27734,-2.882812 -4.67579,0 -7.73438,3.199219 -3.05859,3.234375 -3.05859,8.121093 0,4.921875 2.88281,7.910157 2.88281,3.058593 7.45312,3.058593 4.57032,0 7.52344,-3.339843 2.98828,-3.304688 2.98828,-8.507813 z"
          }
        )
      ]
    }
  );
}

// src/brand/Logo.tsx
var import_brand = require("@dataimago/brand");
var import_jsx_runtime5 = require("react/jsx-runtime");
function Logo({ name, variant = "PATH", width, style, ...rest }) {
  const key = `${name}_${variant}`;
  let markup = import_brand.svgs[key];
  if (!markup) {
    console.warn(`[@dataimago/ui] <Logo>: unknown mark "${key}".`);
    return null;
  }
  if (width != null) {
    markup = markup.replace(/\swidth="[^"]*"/, ` width="${width}"`).replace(/\sheight="[^"]*"/, "");
  }
  return /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(
    "span",
    {
      style: { display: "inline-flex", ...style },
      dangerouslySetInnerHTML: { __html: markup },
      ...rest
    }
  );
}

// src/brand/BrandAnimation.tsx
var React2 = __toESM(require("react"), 1);
var import_brand2 = require("@dataimago/brand");
var import_jsx_runtime6 = require("react/jsx-runtime");
function usePrefersReducedMotion() {
  const [reduced, setReduced] = React2.useState(true);
  React2.useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReduced(mq.matches);
    const onChange = (e) => setReduced(e.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);
  return reduced;
}
function BrandAnimation({
  name,
  width,
  style,
  ...rest
}) {
  const reduced = usePrefersReducedMotion();
  const entry = import_brand2.animationManifest.find((a) => a.id === name);
  let markup = import_brand2.animations[name];
  if (!entry || !markup) {
    console.warn(`[@dataimago/ui] <BrandAnimation>: unknown animation "${name}".`);
    return null;
  }
  if (reduced) {
    return /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(
      Logo,
      {
        name: entry.poster.id,
        variant: entry.poster.variant,
        width,
        style,
        ...rest
      }
    );
  }
  if (width != null) {
    markup = markup.replace(/\swidth="[^"]*"/, ` width="${width}"`).replace(/\sheight="[^"]*"/, "");
  }
  return /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(
    "span",
    {
      style: { display: "inline-flex", ...style },
      dangerouslySetInnerHTML: { __html: markup },
      ...rest
    }
  );
}

// src/brand/NavbarLogo.tsx
var React3 = __toESM(require("react"), 1);
var import_brand3 = require("@dataimago/brand");
var import_jsx_runtime7 = require("react/jsx-runtime");
function usePrefersReducedMotion2() {
  const [reduced, setReduced] = React3.useState(true);
  React3.useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReduced(mq.matches);
    const onChange = (e) => setReduced(e.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);
  return reduced;
}
function NavbarLogo({ name, width, style, ...rest }) {
  const reduced = usePrefersReducedMotion2();
  const entry = import_brand3.navbarManifest.find((n) => n.id === name);
  let markup = import_brand3.navbarLogos[name];
  if (!entry || !markup) {
    console.warn(`[@dataimago/ui] <NavbarLogo>: unknown navbar mark "${name}".`);
    return null;
  }
  if (reduced) {
    return /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(
      Logo,
      {
        name: entry.poster.id,
        variant: entry.poster.variant,
        width,
        style,
        ...rest
      }
    );
  }
  if (width != null) {
    markup = markup.replace(/\swidth="[^"]*"/, ` width="${width}"`).replace(/\sheight="[^"]*"/, "");
  }
  return /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(
    "span",
    {
      style: { display: "inline-flex", ...style },
      dangerouslySetInnerHTML: { __html: markup },
      ...rest
    }
  );
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  BrandAnimation,
  Button,
  Logo,
  LogoMonogram,
  LogoMonogramBg,
  LogoWordmark,
  NavbarLogo
});
//# sourceMappingURL=index.cjs.map