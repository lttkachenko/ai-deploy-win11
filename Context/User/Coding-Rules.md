# ENTERPRISE SPECIFICATION: CODE EDITING AND LINTING RULES

## 📌 Context & Execution Rules
This document establishes absolute code style constraints and formatting layouts mapped directly from active configuration dotfiles (`.editorconfig`, `.prettierrc`, `.prettierignore`, `.stylelintrc`). 
All AI-driven file modifications, test generations, and boilerplate scaffolding executed by Aider inside the workspace MUST adhere strictly to these defined properties to avoid CI/CD pipeline regression blocks.
All comments in code MUST be in English only to ensure international teams usability.
---

## 🛠 1. CORE FILES & INTERFACES LAYOUT (.editorconfig)
*Global IDE and editor configuration rules enforced via INI specification.*

```ini
# Core baseline editor styling parameters
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 2
indent_style = space
insert_final_newline = true
trim_trailing_whitespace = true
```

### Key Constraints:
- **Tabs vs Spaces:** Hard tabs are banned. Always utilize exactly 2 soft spaces per indent level.
- **Line Endings:** Unix-style LF line breaks only. No CRLF mutations allowed.
- **File Endings:** Every script block must terminate with a final trailing newline sequence. No exceptions.
- **English Only:** All the identifiers, names and comments must be in English only for the reason stated above.
---

## 📦 2. ANY CODE FILES AST FORMATTING (.prettierrc)
*Declarative constraints for JavaScript & TypeScript, SQL, Prisma, Bash, PowerShell, layouts, etc. rendering nodes.*

```json
{
  "printWidth": 120,
  "trailingComma": "es5",
  "tabWidth": 2,
  "singleQuote": true,
  "arrowParens": "avoid"
}
```

### Key Constraints:
- **Maximum Line Bound:** Code sheets must break early. Hard limit is 120 characters per line maximum.
- **Strings Mutation:** Strictly enforce single quotes (`'string'`). Double quotes are forbidden unless escaping characters.
- **Arrow Syntaxes:** Lambda parameters under one single argument must drop parenthesis (`x => {}` instead of `(x) => {}`).
- **Trailing Commas:** Enforce ES5-compliant trailing commas where valid (objects, arrays).

---

## 🚫 3. EXCLUSION MATRIX (.prettierignore)
*Static path boundaries ignored by AST parsing engines.*

```text
node_modules/**
```
*Note: Do not trigger formatting evaluation cycles inside dependency bundles.*

---

## 🎨 4. CSS & SCSS STYLE SHEET VALIDATION (.stylelintrc)
*Linting heuristics governing structural style sheets and cascaded layouts.*

```json
{
  "plugins": [
    "stylelint-scss"
  ],
  "rules": {
    "at-rule-no-unknown": null,
    "scss/at-rule-no-unknown": true,
    "scss/selector-no-redundant-nesting-selector": true
  }
}
```

### Key Constraints:
- **SCSS At-Rules Isolation:** Native CSS `@at-rule` checking is decoupled (`null`) to prevent compilation locks on advanced preprocessor syntax.
- **Strict SCSS Scoping:** Enforce strict compliance for unknown SCSS decorators (`scss/at-rule-no-unknown: true`).
- **Nesting Optimization:** Redundant parent reference nesting selectors (`&`) inside SCSS components are blocked (`scss/selector-no-redundant-nesting-selector: true`). Keep the AST selectors flat and optimized.
