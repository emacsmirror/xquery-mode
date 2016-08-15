;;; xquery-mode.el --- A simple mode for editing xquery programs

;; Copyright (C) 2005 Suraj Acharya
;; Copyright (C) 2006-2012 Michael Blakeley

;; Authors:
;;   Suraj Acharya <sacharya@cs.indiana.edu>
;;   Michael Blakeley <mike@blakeley.com>
;; URL: https://github.com/xquery-mode/xquery-mode
;; Version: 0.1.0

;; This file is not part of GNU Emacs.

;; xquery-mode.el is free software; you can redistribute it
;; and/or modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

;; TODO: 'if()' is highlighted as a function
;; TODO: requiring nxml-mode excludes XEmacs - just for colors?
;; TODO: test using featurep 'xemacs
;; TODO use nxml for element completion?

(require 'font-lock)
(require 'nxml-mode)

(defgroup xquery-mode nil
  "Major mode for XQuery files editing."
  :group 'languages)

(defun turn-on-xquery-tab-to-tab-indent ()
  "Turn on tab-to-tab XQuery-mode indentation."
  (define-key xquery-mode-map (kbd "TAB") 'tab-to-tab-stop))

(defun turn-on-xquery-native-indent ()
  "Turn on native XQuery-mode indentation."
  (define-key xquery-mode-map (kbd "TAB") 'indent-for-tab-command))

(defun toggle-xquery-mode-indent-style ()
  "Switch to the next indentation style."
  (interactive)
  (if (eq xquery-mode-indent-style 'tab-to-tab)
      (setq xquery-mode-indent-style 'native)
    (setq xquery-mode-indent-style 'tab-to-tab))
  (xquery-mode-activate-indent-style))

(defun xquery-mode-activate-indent-style ()
  "Activate current indentation style."
  (cond ((eq xquery-mode-indent-style 'tab-to-tab)
         (turn-on-xquery-tab-to-tab-indent))
        ((eq xquery-mode-indent-style 'native)
         (turn-on-xquery-native-indent))))

(defcustom xquery-mode-hook nil
  "Hook run after entering XQuery mode."
  :type 'hook
  :options '(turn-on-xquery-indent turn-on-font-lock))

(defvar xquery-toplevel-bovine-table nil
  "Top level bovinator table.")

(defvar xquery-mode-syntax-table ()
  "Syntax table for xquery-mode.")

(setq xquery-mode-syntax-table
      (let ((xquery-mode-syntax-table (make-syntax-table)))
        ;; single-quotes are equivalent to double-quotes
        (modify-syntax-entry ?' "\"" xquery-mode-syntax-table)
        ;; treat underscores as punctuation
        (modify-syntax-entry ?\_ "." xquery-mode-syntax-table)
        ;; treat hypens as punctuation
        (modify-syntax-entry ?\- "." xquery-mode-syntax-table)
        ;; colons are both punctuation and comments
        ;; the space after '.' indicates an unused matching character slot
        (modify-syntax-entry ?\: ". 23" xquery-mode-syntax-table)
        ;; XPath step separator / is punctuation
        (modify-syntax-entry ?/ "." xquery-mode-syntax-table)
        ;; xquery doesn't use backslash-escaping, so \ is punctuation
        (modify-syntax-entry ?\\ "." xquery-mode-syntax-table)
        ;; set-up the syntax table correctly for all the different braces
        (modify-syntax-entry ?\{ "(}" xquery-mode-syntax-table)
        (modify-syntax-entry ?\} "){" xquery-mode-syntax-table)
        (modify-syntax-entry ?\[ "(]" xquery-mode-syntax-table)
        (modify-syntax-entry ?\] ")]" xquery-mode-syntax-table)
        ;; parens may indicate a comment, or may be a sequence
        (modify-syntax-entry ?\( "()1n" xquery-mode-syntax-table)
        (modify-syntax-entry ?\) ")(4n" xquery-mode-syntax-table)
        xquery-mode-syntax-table))

(defvar xquery-mode-keywords ()
  "Keywords for xquery-mode.")

(defvar xquery-mode-comment-start "(: "
  "String used to start an XQuery mode comment.")

(defvar xquery-mode-comment-end " :)"
  "String used to end an XQuery mode comment.")

(defvar xquery-mode-comment-fill ":"
  "String used to fill an XQuery mode comment.")

(defvar xquery-mode-comment-start-skip "(:\\s-+"
  "Regexp to match an XQuery mode comment and any following whitespace.")

;;;###autoload
(define-derived-mode xquery-mode fundamental-mode "XQuery"
  "A major mode for W3C XQuery 1.0"
  ;; indentation
  (xquery-set-indent-function)
  (setq tab-width xquery-mode-indent-width)
  (set (make-local-variable 'indent-line-function) 'xquery-indent-line)
  ;; apparently it's important to set at least an empty list up-front
  (set (make-local-variable 'font-lock-defaults) '((nil)))
  (set (make-local-variable 'comment-start) xquery-mode-comment-start)
  (set (make-local-variable 'comment-end) xquery-mode-comment-end)
  (set (make-local-variable 'comment-fill)  xquery-mode-comment-fill)
  (set (make-local-variable 'comment-start-skip) xquery-mode-comment-start-skip))

;; TODO: move it upper.
(defcustom xquery-mode-indent-style 'tab-to-tab
  "Indentation behavior.
`tab-to-tab' to use `tab-to-tab-stop' indent function
`native' to use own indentation engine"
  :group 'xquery-mode
  :type '(choice (const :tag "Tab to tab" tab-to-tab)
                 (const :tag "Native" native))
  :set (lambda (var key)
         (set var key)
         (xquery-mode-activate-indent-style)))

(defcustom xquery-mode-indent-width 2
  "Indent width for `xquery-mode'."
  :group 'xquery-mode
  :type 'integer)

;; XQuery doesn't have keywords, but these usually work...
;; TODO: remove as many as possible, in favor of parsing
(setq xquery-mode-keywords
      (list
       ;; FLWOR
       ;;"let" "for"
       "at" "in"
       "where"
       "stable order by" "order by"
       "ascending" "descending" "empty" "greatest" "least" "collation"
       "return"
       ;; XPath axes
       "self" "child" "descendant" "descendant-or-self"
       "parent" "ancestor" "ancestor-or-self"
       "following" "following-sibling"
       "preceding" "preceding-sibling"
       ;; conditionals
       "if" "then" "else"
       "typeswitch" ;"case" "default"
       ;; quantified expressions
       "some" "every" "construction" "satisfies"
       ;; schema
       "schema-element" "schema-attribute" "validate"
       ;; operators
       "intersect" "union" "except" "to"
       "is" "eq" "ne" "gt" "ge" "lt" "le"
       "or" "and"
       "div" "idiv" "mod"))

(defvar xquery-mode-keywords-regex
  (concat "\\b\\("
          (mapconcat
           (function
            (lambda (r)
              (if (string-match "[ \t]+" r)
                  (replace-match "[ \t]+" nil t r)
                r)))
           xquery-mode-keywords
           "\\|")
          "\\)\\b")
  "Keywords regex for xquery mode.")

;; XQuery syntax - TODO build a real parser
(defvar xquery-mode-ncname "\\(\\sw[-_\\.[:word:]]*\\)"
  "NCName regex, in 1 group.")

;; highlighting needs a group, even if it's "" - so use (...?) not (...)?
;; note that this technique treats the local-name as optional,
;; when the prefix should be the optional part.
(defvar xquery-mode-qname
  (concat
   xquery-mode-ncname
   "\\(:?\\)"
   "\\("
   xquery-mode-ncname
   "?\\)")
  "QName regex, in 3 groups.")

;; highlighting
;; these are "matcher . highlighter" forms
(font-lock-add-keywords
 'xquery-mode
 `(
   ;; prolog version decl
   ("\\(xquery\\s-+version\\)\\s-+"
    (1 font-lock-keyword-face))
   ;; namespace default decl for 0.9 or 1.0
   (,(concat
      "\\(\\(declare\\)?"
      "\\(\\s-+default\\s-+\\(function\\|element\\)\\)"
      "\\s-+namespace\\)\\s-+")
    (1 font-lock-keyword-face))
   ;; namespace decl
   (,(concat
      "\\(declare\\s-+namespace\\)\\s-+")
    (1 font-lock-keyword-face))
   ;; option decl
   (,(concat "\\(declare\\s-+option\\s-+" xquery-mode-qname "\\)")
    (1 font-lock-keyword-face))
   ;; import module decl - must precede library module decl
   ("\\(import\\s-+module\\)\\s-+\\(namespace\\)?\\s-+"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;; library module decl, for 1.0 or 0.9-ml
   ("\\(module\\)\\s-+\\(namespace\\)?\\s-*"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;; import schema decl
   ("\\(import\\s-+schema\\)\\s-+\\(namespace\\)?\\s-+"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;; variable decl
   ("\\(for\\|let\\|declare\\s-+variable\\|define\\s-+variable\\)\\s-+\\$"
    (1 font-lock-keyword-face))
   ;; variable name
   (,(concat "\\($" xquery-mode-qname "\\)")
    (1 font-lock-variable-name-face))
   ;; function decl
   (,(concat
      "\\(declare\\s-+function\\"
      "|declare\\s-+private\\s-+function\\"
      "|define\\s-+function\\)\\s-+\\("
      xquery-mode-qname "\\)(")
    (1 font-lock-keyword-face)
    (2 font-lock-function-name-face))
   ;; schema test or type decl
   (,(concat
      "\\("
      "case"
      "\\|instance\\s-+of\\|castable\\s-+as\\|treat\\s-+as\\|cast\\s-+as"
      ;; "as" must be last in the list
      "\\|as"
      "\\)"
      "\\s-+\\(" xquery-mode-qname "\\)"
      ;; type may be followed by element() or element(x:foo)
      "(?\\s-*\\(" xquery-mode-qname "\\)?\\s-*)?")
    (1 font-lock-keyword-face)
    (2 font-lock-type-face)
    ;; TODO the second qname never matches
    (3 font-lock-type-face))
   ;; function call
   (,(concat "\\(" xquery-mode-qname "\\)(")
    (1 font-lock-function-name-face))
   ;; named node constructor
   (,(concat "\\(attribute\\|element\\)\\s-+\\(" xquery-mode-qname "\\)\\s-*{")
    (1 font-lock-keyword-face)
    (2 font-lock-constant-face))
   ;; anonymous node constructor
   ("\\(binary\\|comment\\|document\\|text\\)\\s-*{"
    (1 font-lock-keyword-face))
   ;; typeswitch default
   ("\\(default\\s-+return\\)\\s-+"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;;
   ;; highlighting - use nxml config to font-lock directly-constructed XML
   ;;
   ;; xml start element start
   (,(concat "<" xquery-mode-qname)
    (1 'nxml-element-prefix-face)
    (2 'nxml-element-colon-face)
    (3 'nxml-element-prefix-face))
   ;; xml start element end
   ("\\(/?\\)>"
    (1 'nxml-tag-slash-face))
   ;; xml end element
   (,(concat "<\\(/\\)" xquery-mode-qname ">")
    (1 'nxml-tag-slash-face)
    (2 'nxml-element-prefix-face)
    (3 'nxml-element-colon-face)
    (4 'nxml-element-local-name-face))
   ;; TODO xml attribute or xmlns decl
   ;; xml comments
   ("\\(<!--\\)\\([^-]*\\)\\(-->\\)"
    (1 'nxml-comment-delimiter-face)
    (2 'nxml-comment-content-face)
    (3 'nxml-comment-delimiter-face))
   ;; highlighting XPath expressions, including *:foo
   ;; TODO this doesn't match expressions unless they start with slash
   ;; TODO but matching without a leading slash overrides all the keywords
   (,(concat "\\(//?\\)\\(*\\|\\sw*\\)\\(:?\\)" xquery-mode-ncname)
    (1 font-lock-constant-face)
    (2 font-lock-constant-face)
    (3 font-lock-constant-face)
    (4 font-lock-constant-face))
   ;;
   ;; highlighting pseudo-keywords - must be late, for problems like 'if ()'
   ;;
   (,xquery-mode-keywords-regex (1 font-lock-keyword-face))))

;;;###autoload
(add-to-list 'auto-mode-alist '(".xq[erxy]\\'" . xquery-mode))

(defun xquery-forward-sexp (&optional arg)
  "XQuery forward s-expresssion.
This function is not very smart.  It tries to use
`nxml-forward-balanced-item' if it sees '>' or '<' characters in
the current line (ARG), and uses the regular `forward-sexp'
otherwise."
  (if (> arg 0)
      (progn
        (if (looking-at "\\s-*<")
            (nxml-forward-balanced-item arg)
          (let ((forward-sexp-function nil)) (forward-sexp arg))))
    (if (looking-back ">\\s-*")
        (nxml-forward-balanced-item arg)
      (let ((forward-sexp-function nil)) (forward-sexp arg)))))

(defvar xquery-indent-size tab-width
  "The size of each indent level.")

(defun xquery-set-indent-function ()
  "Set the indent function for xquery mode."
  (setq nxml-prolog-end (point-min))
  (setq nxml-scan-end (copy-marker (point-min) nil))
  (set (make-local-variable 'indent-line-function) 'xquery-indent-line)
  (make-local-variable 'forward-sexp-function)
  (setq forward-sexp-function 'xquery-forward-sexp)
  (local-set-key "/" 'nxml-electric-slash))

(defun xquery-indent-line ()
  "Indent current line as xquery code."
  (interactive)
  (let ((savept (> (current-column) (current-indentation)))
        (indent (car (xquery-calculate-indentation))))
    (if (> indent -1)
        (if savept
            (save-excursion (indent-line-to indent))
          (indent-line-to (max 0 indent))))))

(defun xquery-indent-via-nxml ()
  "This function use nxml to calculate the indentation."
  (let ((nxml-prolog-end (point-min))
        (nxml-scan-end (copy-marker (point-min) nil)))
    (nxml-compute-indent)))

(defvar xquery-indent-regex
  (concat "^\\s-*\\("
          "typeswitch\\|for\\|let\\|where\\|order\\s-+by\\|return"
          "\\|if\\|then\\|else"
          "\\)\\s-*$")
  "A regular expression indicating an indentable xquery sub-expression.")

(defun xquery-calculate-indentation ()
  "Calculate the indentation for a line of XQuery.
This function returns the column to which the current line should
be indented."
  (save-excursion
    (beginning-of-line)
    (cl-destructuring-bind
        (results-bol
         paren-level-bol
         list-start-bol
         sexp-start-bol
         stringp-bol
         comment-level-bol
         quotep-bol
         min-level-bol
         bcommentp-bol
         comment-start-bol)
        (save-excursion (parse-partial-sexp (point-min) (point)))
      (let* ((point-eol (line-end-position))
             (results-eol (save-excursion (parse-partial-sexp (point-min) point-eol)))
             (results-nxml
              (when (or (looking-at "\\s-*<!--")
                        (looking-at "\\s-*-->")
                        (looking-at "\\s-*<\\sw+")
                        (looking-at "\\s-*</?\\sw+"))
                (xquery-indent-via-nxml)))
             (nxml-indent
              (when results-nxml
                (/ results-nxml xquery-indent-size))))
        (let* ((paren-level-eol (car results-eol))
               (indent
                (cond
                 ((eq (point-min) (line-beginning-position))
                  0)
                 (comment-level-bol
                  ;; within a multi-line comment start of comment
                  ;; indentation + 1
                  (+ 1 (save-excursion
                         (goto-char comment-start-bol)
                         (current-indentation))))
                 ;; TODO multi-line prolog variable?
                 (nil -1)
                 ;; mult-line module import?
                 ((and (save-excursion
                         (beginning-of-line)
                         (looking-at "^\\s-*at\\s-+"))
                       (save-excursion
                         (beginning-of-line)
                         (previous-line)
                         (looking-at "^\\s-*import\\s-+module\\s-+")))
                  xquery-indent-size)
                 ;; multi-line function decl?
                 ;; TODO handle more than 1 line previous
                 ((and (save-excursion
                         (beginning-of-line)
                         (looking-at "^\\s-*as\\s-+"))
                       (save-excursion
                         (beginning-of-line)
                         (previous-line)
                         (looking-at
                          "^\\s-*\\(define\\|declare\\)\\s-+function\\s-+")))
                  xquery-indent-size)
                 ;; Close paren at start of line is usually the end of
                 ;; a list of function parameters. Leave it at the beginning
                 ;; of the line
                 ((save-excursion
                    (beginning-of-line)
                    (looking-at "^)"))
                  0)
                 ;; Open or close curly brace at the beginning of a line
                 ;; is a block start or end. Leave it at the beginning of
                 ;; the line.
                 ((save-excursion
                    (beginning-of-line)
                    (or (looking-at "^{")
                        (looking-at "^}")))
                  0)
                 ;; Indent else
                 ((save-excursion
                    (beginning-of-line)
                    (looking-at "^\\s-*else\\s-*"))
                  (save-excursion
                    (search-backward "then")
                    (current-column)))
                 ;; Indent after else
                 ((save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (looking-at "^\\s-*else\\s-*"))
                  (save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (search-forward "else")
                    (+ (- (current-column) 4) xquery-indent-size)))
                 ;; Indent up to if
                 ((save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (looking-at "^\\s-*if\\s-*\("))
                  (save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (search-forward "if")
                    (- (current-column) 2)))
                 ;; Indent after then
                 ((save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (looking-at "^\\s-*then\\s-*"))
                  (save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (search-forward "then")
                    (+ (- (current-column) 4) xquery-indent-size)))
                 ;; Indent after return
                 ((save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (looking-at "^\\s-*return\\s-*"))
                  (save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (search-forward "return")
                    (+ (- (current-column) 6) xquery-indent-size)))
                 ;; Indent up to let
                 ((save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (looking-at "^\\s-*let\\s-*"))
                  (save-excursion
                    (beginning-of-line)
                    (previous-line)
                    (search-forward "let")
                    (- (current-column) 3)))
                 ;; default - use paren-level-bol
                 (t (* xquery-indent-size
                       ;; special when simply closing 1 level
                       (cond
                        ((and (= paren-level-bol (+ 1 paren-level-eol))
                              (looking-at "^\\s-*\\s)[,;]?\\s-*$") )
                         paren-level-eol)
                        ;; factor in the nxml-indent
                        ((and
                          nxml-indent (> nxml-indent paren-level-bol))
                         nxml-indent)
                        (t paren-level-bol)))))))
          (list (min 70 indent) results-bol results-eol))))))

(provide 'xquery-mode)

;;; xquery-mode.el ends here
