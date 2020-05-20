(lang dune 2.5)
(name spawn)

(generate_opam_files true)

(maintainers opensource@janestreet.com)
(source (github janestreet/spawn))
(documentation https://janestreet.github.io/spawn/)
(authors  "Jane Street Group, LLC <opensource@janestreet.com>")
(license MIT)

(package
 (name spawn)
 (depends
  (ppx_expect :with-test)
  (ocaml (>= 4.02.3))))
