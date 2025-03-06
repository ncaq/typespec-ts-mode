;;; typespec-ts-mode.el --- Major mode for TypeSpec using tree-sitter  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 ncaq.

;; Author: ncaq <ncaq@ncaq.net>
;; Maintainer: ncaq <ncaq@ncaq.net>
;; URL: https://github.com/ncaq/typespec-ts-mode

;; Package: typespec-ts-mode
;; Keywords: typespec languages tree-sitter

;; Package-Version: 0.0.0
;; Package-Requires: ((emacs "29.1"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for [TypeSpec](https://typespec.io/) using [tree-sitter](https://tree-sitter.github.io/tree-sitter/).

;; This package was inspired by and includes code from the following project:
;; - [typespec](https://github.com/microsoft/typespec/)
;;   Copyright (c) Microsoft Corporation.
;;   Licensed under the [MIT License](https://github.com/microsoft/typespec/blob/12266404f18bdf42ac570b25ad17b92b99ca890a/LICENSE)
;; - [tree-sitter-typespec](https://github.com/happenslol/tree-sitter-typespec)
;;   Copyright (c) 2024 Hilmar Wiegand
;;   Licensed under the [MIT License](https://github.com/happenslol/tree-sitter-typespec/blob/0ee05546d73d8eb64635ed8125de6f35c77759fe/LICENSE)

;;; Code:

(require 'treesit)

(require 'c-ts-common)

(defcustom typespec-ts-mode-grammar
  '("https://github.com/happenslol/tree-sitter-typespec/")
  "URL or a cons cell of URL and revision.
Configuration for downloading and installing
the tree-sitter `typespec-ts-mode' grammar."
  :type '(choice (string :tag "URL")
           (cons :tag "URL and Revision"
             (string :tag "URL")
             (string :tag "Revision")))
  :group 'typespec-ts)

(defcustom typespec-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `typespec-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'typespec-ts)

(defvar typespec-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    ;; Taken from the cc-langs version
    (modify-syntax-entry ?_    "_"      table)
    (modify-syntax-entry ?\\   "\\"     table)
    (modify-syntax-entry ?+    "."      table)
    (modify-syntax-entry ?-    "."      table)
    (modify-syntax-entry ?=    "."      table)
    (modify-syntax-entry ?%    "."      table)
    (modify-syntax-entry ?<    "."      table)
    (modify-syntax-entry ?>    "."      table)
    (modify-syntax-entry ?&    "."      table)
    (modify-syntax-entry ?|    "."      table)
    (modify-syntax-entry ?\'   "\""     table)
    (modify-syntax-entry ?\240 "."      table)
    (modify-syntax-entry ?/    ". 124b" table)
    (modify-syntax-entry ?*    ". 23"   table)
    (modify-syntax-entry ?\n   "> b"    table)
    (modify-syntax-entry ?\^m  "> b"    table)
    (modify-syntax-entry ?$    "_"      table)
    (modify-syntax-entry ?`    "\""     table)
    table)
  "Syntax table for `typespec-ts-mode'.")

(defvar typespec-ts-mode--indent-rules
  `((typespec
      ((parent-is "source_file") column-0 0)
      ((node-is "}") parent-bol 0)
      ((node-is ")") parent-bol 0)
      ((node-is ">") parent-bol 0)
      ((node-is "]") parent-bol 0)
      ((and (parent-is "comment") c-ts-common-looking-at-star)
        c-ts-common-comment-start-after-first-star -1)
      ((parent-is "comment") prev-adaptive-prefix 0)
      ((parent-is "model_expression") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "tuple_expression") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "namespace_body") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "interface_body") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "union_body") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "enum_body") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "template_arguments") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "template_parameters") parent-bol typespec-ts-mode-indent-offset)
      ((parent-is "operation_arguments") parent-bol typespec-ts-mode-indent-offset)))
  "`typespec-ts-mode' Rules used for indentation.")

(defvar typespec-ts-mode--keyword-operator
  '("is" "extends" "valueof")
  "`typespec-ts-mode' @keyword.operator by query.")

(defvar typespec-ts-mode--keyword-type
  '("namespace" "model" "scalar" "interface" "enum" "union" "alias")
  "`typespec-ts-mode' @keyword.operator by query.")

(defvar typespec-ts-mode--keyword-function
  '("op" "fn" "dec")
  "`typespec-ts-mode' @keyword.function by query.")

(defvar typespec-ts-mode--keyword-modifier
  '("extern")
  "`typespec-ts-mode' @keyword.modifier by query.")

(defvar typespec-ts-mode--keyword-import
  '("import" "using")
  "`typespec-ts-mode' @keyword.import by query.")

(defvar typespec-ts-mode--punctuation-bracket
  '("(" ")" "{" "}" "<" ">" "[" "]")
  "`typespec-ts-mode' @punctuation.bracket by query.")

(defvar typespec-ts-mode--punctuation-delimiter
  '("," ";" "." ":")
  "`typespec-ts-mode' @punctuation.delimiter by query.")

(defvar typespec-ts-mode--operator
  '("|" "&" "=" "...")
  "`typespec-ts-mode' @operator by query.")

(defvar typespec-ts-mode--punctuation-special
  '("?")
  "`typespec-ts-mode' @punctuation.special by query.")

(defvar typespec-ts-mode--font-lock-settings
  (treesit-font-lock-rules
    :language 'typespec
    :feature 'type
    `([ (identifier_or_member_expression)
        (builtin_type)
        ]
       @font-lock-type-face
       (model_statement     name: (identifier) @font-lock-type-face)
       (union_statement     name: (identifier) @font-lock-type-face)
       (scalar_statement    name: (identifier) @font-lock-type-face)
       (interface_statement name: (identifier) @font-lock-type-face)
       (enum_statement      name: (identifier) @font-lock-type-face)
       (template_parameter  name: (identifier) @font-lock-type-face)
       (alias_statement     name: (identifier) @font-lock-type-face))

    :language 'typespec
    :feature 'operator
    `([,@typespec-ts-mode--operator] @font-lock-operator-face)

    :language 'typespec
    :feature 'keyword
    `([ ,@typespec-ts-mode--keyword-operator
        ,@typespec-ts-mode--keyword-type
        ,@typespec-ts-mode--keyword-function
        ,@typespec-ts-mode--keyword-modifier
        ,@typespec-ts-mode--keyword-import
        ]
       @font-lock-keyword-face)

    :language 'typespec
    :feature 'bracket
    `([,@typespec-ts-mode--punctuation-bracket] @font-lock-bracket-face)

    :language 'typespec
    :feature 'delimiter
    `( [,@typespec-ts-mode--punctuation-delimiter] @font-lock-delimiter-face
       [,@typespec-ts-mode--punctuation-special  ] @font-lock-misc-punctuation-face)

    :language 'typespec
    :feature 'comment
    `([(single_line_comment) (multi_line_comment)] @font-lock-comment-face)

    :language 'typespec
    :feature 'string
    `([(quoted_string_literal) (triple_quoted_string_literal)] @font-lock-string-face)

    :language 'typespec
    :feature 'constant
    `(((boolean_literal) @font-lock-constant-face)
       (enum_member name: (identifier) @font-lock-constant-face))

    :language 'typespec
    :feature 'number
    `([(decimal_literal) (hex_integer_literal) (binary_integer_literal)] @font-lock-number-face)

    :language 'typespec
    :feature 'escape-sequence
    `((escape_sequence) @font-lock-escape-face)

    :language 'typespec
    :feature 'attribute
    `( (decorator
         ("@") @font-lock-property-name-face
         name: (identifier_or_member_expression) @font-lock-property-name-face)
       (augment_decorator_statement     name: (identifier) @font-lock-property-name-face)
       (decorator_declaration_statement name: (identifier) @font-lock-property-name-face))

    :language 'typespec
    :feature 'module
    `( (using_statement module: (identifier_or_member_expression) @font-lock-type-face)
       (namespace_statement name: (identifier_or_member_expression) @font-lock-type-face))

    :language 'typespec
    :feature 'variable-member
    `( (model_property name: (identifier) @font-lock-variable-name-face)
       (union_variant  name: (identifier) @font-lock-variable-name-face))

    :language 'typespec
    :feature 'variable-parameter
    `( (function_parameter name: (identifier) @font-lock-variable-use-face)
       (operation_arguments name: (identifier) @font-lock-variable-use-face))

    :language 'typespec
    :feature 'function
    `(operation_statement name: (identifier) @font-lock-function-name-face))
  "Tree-sitter font-lock settings for `typespec-ts-mode'.")

(defvar typespec-ts-mode--font-lock-feature-list
  '( (comment module variable-member)
     (keyword string escape-sequence)
     (constant identifier number pattern attribute type)
     (function bracket delimiter))
  "Tree-sitter font-lock feature list for `typespec-ts-mode'.")

;;;###autoload
(defun typespec-ts-mode-grammar-install ()
  "Install the TypeSpec tree-sitter grammar."
  (interactive)
  (let ((treesit-language-source-alist `((typespec . ,(ensure-list typespec-ts-mode-grammar)))))
    (treesit-install-language-grammar 'typespec))
  (unless (treesit-ready-p 'typespec)
    (error "Tree-sitter for TypeSpec isn't available")))

;;;###autoload
(define-derived-mode typespec-ts-mode prog-mode "TypeSpec"
  "Major mode for TypeSpec using tree-sitter."
  :syntax-table typespec-ts-mode--syntax-table
  :group 'typespec-ts

  (when (treesit-ready-p 'typespec)
    (treesit-parser-create 'typespec)

    ;; Comments.
    (c-ts-common-comment-setup)

    ;; Font-lock.
    (setq-local treesit-font-lock-settings typespec-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list typespec-ts-mode--font-lock-feature-list)

    ;; Indent.
    (setq-local treesit-simple-indent-rules typespec-ts-mode--indent-rules)

    (treesit-major-mode-setup)))

;;; Top-level execute code.

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.tsp\\'" . typespec-ts-mode))

(provide 'typespec-ts-mode)

;;; typespec-ts-mode.el ends here
