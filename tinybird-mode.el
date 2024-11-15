;;; tinybird-mode.el --- Major mode for Tinybird Datafiles. -*- lexical-binding: t -*-

;; Copyright (c) 2024 Sergio Conde

;; URL: https://github.com/skgsergio/tinybird-mode
;; Version: 0.01
;; Package-Requires: ((emacs "24"))
;; Keywords: tinybird

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Syntax highlighting support for tinybird .datasource, .pipe and .incl files.

;;; Code:

(eval-when-compile
  (require 'rx))

(defvar tinybird-text-keywords nil "Tinybird text keywords.")
(setq tinybird-text-keywords
      (eval-when-compile
        (append
         '("DESCRIPTION" "INCLUDE" "FILTER" "NODE" "TAGS" "SHARED_WITH" "TYPE" "DATASOURCE" "TARGET_DATASOURCE"
           "COPY_SCHEDULE" "COPY_MODE" "APPEND" "ENGINE")
         (mapcar
          (lambda (x) (format "ENGINE_%s" x))
          '("PARTITION_KEY" "PRIMARY_KEY" "SORTING_KEY" "SAMPLING_KEY" "SETTINGS" "VER" "SIGN" "TTL"))
         (mapcar
          (lambda (x) (format "IMPORT_%s" x))
          '("SERVICE" "SCHEDULE" "CONNECTION_NAME" "STRATEGY" "BUCKET_URI" "EXTERNAL_DATASOURCE" "QUERY"
            "FROM_DATETIME"))
         (mapcar
          (lambda (x) (format "EXPORT_%s" x))
          '("SERVICE" "CONNECTION_NAME" "SCHEDULE" "BUCKET_URI" "FILE_TEMPLATE" "FORMAT" "COMPRESSION" "STRATEGY"
            "KAFKA_TOPIC"))
         (mapcar
          (lambda (x) (format "KAFKA_%s" x))
          '("CONNECTION_NAME" "STORE_HEADERS" "STORE_BINARY_HEADERS" "KEY_AVRO_DESERIALIZATION" "TOPIC" "GROUP_ID"
            "AUTO_OFFSET_RESET" "BOOTSTRAP_SERVERS" "KEY" "SECRET" "STORE_RAW_VALUE" "TARGET_PARTITIONS"))
         )))

(defvar tinybird-code-keywords nil "Tinybird code keywords.")
(setq tinybird-code-keywords
      '("SQL" "SCHEMA")
      )

(defvar tinybird-sql nil "SQL keywords.")
(setq tinybird-sql
      '("SELECT" "FROM" "WHERE" "GROUP BY" "ORDER BY" "LIMIT" "INSERT" "UPDATE" "DELETE" "JOIN" "LEFT" "RIGHT" "INNER"
        "OUTER" "ON" "AS" "IN" "BETWEEN" "LIKE" "IS" "NULL" "NOT" "WITH" "AND" "OR" "OFFSET" "INTERVAL")
      )

(defvar tinybird-types nil "Supported ClickHouse data types.")
(setq tinybird-types
      '("Int8" "Int16" "Int32" "Int64" "Int128" "Int256" "UInt8" "UInt16" "UInt32" "UInt64" "UInt128" "UInt256" "Float32"
        "Float64" "Decimal" "Decimal32" "Decimal64" "Decimal128" "Decimal256" "String" "FixedString" "UUID" "Date"
        "Date32" "DateTime" "DateTime64" "Bool" "Array" "Map" "Tuple" "SimpleAggregateFunction" "AggregateFunction"
        "LowCardinality" "Nullable" "Nothing")
      )

(defvar tinybird-fontlock nil "Rules for =font-lock-defaults=.")
(setq tinybird-fontlock
      (eval-when-compile
        `(
          ;; Comment
          (,(rx-to-string `(group bol "#" (0+ nonl)))
           (1 font-lock-comment-face))

          ;; Quoted strings
          (,(rx-to-string `(group "\"" (0+ (not (any "\n\""))) "\""))
           (1 font-lock-string-face))
          (,(rx-to-string `(group "'" (0+ (not (any "\n'"))) "'"))
           (1 font-lock-string-face))

          ;; TOKEN "a name" {READ,APPEND}
          (,(rx-to-string `(: bol (group "TOKEN") (1+ " ") (group (| (: "\"" (1+ (| alnum " ")) "\"") (1+ alnum))) (1+ " ") (group (| "READ" "APPEND"))))
           (1 font-lock-builtin-face) (2 font-lock-string-face) (3 font-lock-builtin-face))

          ;; KEYWORD >
          ;;     multi
          ;;     line
          ;;     value
          ;; KEYWORD single line value

          ;; Text keywords
          (,(rx-to-string `(: bol (group (| ,@tinybird-text-keywords)) (1+ " ") (group ">") (0+ " ") (group (0+ "\n" (1+ nonl)))))
           (1 font-lock-builtin-face) (2 font-lock-constant-face) (3 font-lock-string-face))
          (,(rx-to-string `(: bol (group (| ,@tinybird-text-keywords)) (group (| eol (: (1+ " ") (0+ nonl))))))
           (1 font-lock-builtin-face) (2 font-lock-string-face))

          ;; Code keywords
          (,(rx-to-string `(: bol (group (| ,@tinybird-code-keywords)) (1+ " ") (group ">") (0+ " ") (0+ "\n" (1+ nonl))))
           (1 font-lock-builtin-face) (2 font-lock-constant-face))
          (,(rx-to-string `(: bol (group (| ,@tinybird-code-keywords)) (| eol (: (1+ " ") (0+ nonl)))))
           (1 font-lock-builtin-face))

          ;; [SCHEMA] `json:$.wadus` (JSONPath)
          (,(rx-to-string `(: (group "`json:") (group (0+ (not "`"))) (group "`")))
           (1 font-lock-constant-face) (2 font-lock-variable-name-face) (3 font-lock-constant-face))

          ;; [SCHEMA] `column_name`
          (,(rx-to-string `(: (group "`") (group (0+ (not "`"))) (group "`")))
           (1 font-lock-constant-face) (2 font-lock-variable-name-face) (3 font-lock-constant-face))

          ;; [SQL/SCHEMA] ClickHouse Types
          (,(rx-to-string `(: (group (| ,@tinybird-types))))
           (1 font-lock-type-face))

          ;; [SQL/SCHEMA] Functions
          (,(rx-to-string `(: (group (1+ (not (any " \n(")))) "("))
           (1 font-lock-function-name-face))

          ;; [SQL] Keywords
          (,(rx-to-string `(: (group (| ,@tinybird-sql))))
           (1 font-lock-keyword-face))

          ;; [SQL]   % (Templating marker)
          (,(rx-to-string `(: (group (: bol (0+ " ") "%" (0+ " ") eol))))
           (1 font-lock-constant-face))

          ;; [SQL] {{ function/value }} (Templating)
          (,(rx-to-string `(: (group "{{") (0+ nonl) (group "}}")))
           (1 font-lock-constant-face) (2 font-lock-constant-face))
          )))

(defun tinybird-extend-region ()
  "Extend the search region to include an entire block of text."
  (defvar font-lock-beg) (defvar font-lock-end)
  (save-excursion
    (goto-char font-lock-beg)
    (let ((found (or (re-search-backward "\n\n" nil t) (point-min))))
      (goto-char font-lock-end)
      (when (re-search-forward "\n\n" nil t)
        (beginning-of-line)
        (setq font-lock-end (point)))
      (setq font-lock-beg found))))

;;;###autoload
(define-derived-mode tinybird-mode prog-mode "Tinybird"
  "Major mode for editing Tinybird files."
  (setq font-lock-defaults '(tinybird-fontlock t t))
  (add-hook 'font-lock-extend-region-functions 'tinybird-extend-region))

(add-to-list 'auto-mode-alist '("\\.datasource\\'" . tinybird-mode))
(add-to-list 'auto-mode-alist '("\\.pipe\\'" . tinybird-mode))
(add-to-list 'auto-mode-alist '("\\.incl\\'" . tinybird-mode))

(provide 'tinybird-mode)
;;; tinybird-mode.el ends here
