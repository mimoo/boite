open Core

let build path =
  (* find boite.toml *)
  let manifest = Manifest.parse_manifest "Boite.toml" in

  (* make sure opam is installed *)
  let ocaml_version = manifest.ocaml.ocaml_version in
  Opam.init ~ocaml_version path;

  (* check that we have all dependencies *)
  printf "path: %s\n" path;
  printf "built\n"
