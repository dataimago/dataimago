// dataimago Tailwind CSS Preset — Generated from @dataimago/tokens
// Exposes the canonical warm scholarly palette. Consumers add their own
// extensions via the standard `theme.extend` API.

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        ink:    {
                "50": "#f5f5f4",
                "100": "#e7e5e4",
                "200": "#d6d3d1",
                "300": "#a8a29e",
                "400": "#78716c",
                "500": "#57534e",
                "600": "#44403c",
                "700": "#292524",
                "800": "#1c1917",
                "900": "#0c0a09"
        },
        cream:  {
                "50": "#fefdfb",
                "100": "#fdf9f2",
                "200": "#faf2e3",
                "300": "#f5e8cf",
                "400": "#edd9b3",
                "500": "#e0c088"
        },
        copper: {
                "50": "#fdf4ee",
                "100": "#fbe5d1",
                "200": "#f6c79c",
                "300": "#f0a467",
                "400": "#ea8441",
                "500": "#d46820",
                "600": "#b55017",
                "700": "#913d15",
                "800": "#753318",
                "900": "#612b16"
        },
        accent: {
                "50": "#fdf2f2",
                "500": "#b54a27",
                "600": "#9a3e20",
                "700": "#7d321a"
        },
        functional: {
                  "success": "#27AE60",
                  "warning": "#F39C12",
                  "error": "#E74C3C",
                  "info": "#3498DB"
          }
      },
      fontFamily: {
        serif:   ['Cormorant Garamond', 'Georgia', 'serif'],
        sans:    ['Inter', 'system-ui', 'sans-serif'],
        mono:    ['JetBrains Mono', 'SF Mono', 'Monaco', 'monospace'],
        display: ['Inter', 'system-ui', 'sans-serif'],
        brand:   ['Josefin Sans', 'Inter', 'system-ui', 'sans-serif']
      }
    }
  }
};
