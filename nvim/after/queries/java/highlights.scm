;; extends

; Give generic type parameter declarations (the T in class Box<T>) their
; own capture so they can be colored distinctly (teal) from real class
; names, matching IntelliJ's TYPE_PARAMETER_NAME_ATTRIBUTES.
; NOTE: usages of the parameter elsewhere in the body are syntactically
; indistinguishable from class references without semantic info, so this
; only covers the declaration site; coc-java's semantic tokens (CocSem*)
; cover usages when the LSP is active.
(type_parameter
  (type_identifier) @type.parameter)
