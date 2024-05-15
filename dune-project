(lang dune 3.14)

(name ocaml_inets)

(generate_opam_files true)

(source
 (github nikolaushuber/ocaml_inets))

(authors "Nikolaus Huber")

(maintainers "Nikolaus Huber")

(license MIT)

(documentation https://github.com/nikolaushuber/ocaml_inets/)

(package
 (name ocaml_inets)
 (synopsis "Interaction net encodings in OCaml")
 (description "Interaction nets are a graphical programming language based on graph rewriting. This repository holds examples of interaction nets encoded in OCaml, specifically testing out the recently added support for parallel evalution.")
 (depends (ocaml (>= 5.1.1)) dune moonpool)
 (allow_empty)
 (tags
  (thread pool domain futures)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
