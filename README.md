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

# Relationship with [typespec-ts-mode](https://github.com/pradyuman/typespec-ts-mode/tree/main)

There is no relationship whatsoever.
I started writing this software in November 2024,
became roughly practical in December,
and when I decided to register it with melpa with a heavy heart in March,
I noticed that the package was registered under the name `typespec-ts-mode`.
It seems that typespec-ts-mode was developed around January.
I have no ill feelings towards typespec-ts-mode at all.
Before tree-sitter,
it would have been a bad idea to split the package because it would have distributed development resources,
but this is like the main body of tree-sitter's main rules,
so you don't have to worry about it too much.
However, I also went through the trouble of writing up the package besides improving tree-sitter itself,
so I'm going to release it as such.
