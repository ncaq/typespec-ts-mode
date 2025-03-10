# typespec-ts-mode

Major mode for [TypeSpec](https://typespec.io/) using [tree-sitter](https://tree-sitter.github.io/tree-sitter/).

This mode uses [tree-sitter-typespec](https://github.com/happenslol/tree-sitter-typespec/) for syntax rules.

# Prerequisites

* `(treesit-available-p)` -> `t`
* `(treesit-library-abi-version)` -> support `15`

# Grammar Installation

I have a PR out to [treesit-auto](https://github.com/renzmann/treesit-auto) and will use that when it is imported.
Or run the `(typespec-ts-mode-grammar-install)` only the first time.

# LSP

lsp-mode already supports typespec.
[TypeSpec - LSP Mode - LSP support for Emacs](https://emacs-lsp.github.io/lsp-mode/page/lsp-typespec/)
