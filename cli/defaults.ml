open Core

(** minimum version of opam we support *)
let opam_version : Semver.t = Option.value_exn (Semver.of_string "2.0.8")

(** default version of OCaml *)
let ocaml_version = "4.12.0"

(** default version of dune *)
let dune_version = "2.8.5"

(** default manifest *)
let manifest =
  let s =
    {|
[package]
name = "{{name}}"
version = "0.1.0"

[ocaml]
ocaml_version = "{{ocaml_version}}"

# your dependencies go here
[dependencies]
base = "0.14.1"

|}
  in
  String.substr_replace_first s ~pattern:"{{ocaml_version}}"
    ~with_:ocaml_version

(** default lib.ml file *)
let lib_ml =
  {| 
open Base

let%test_module _ = (module struct
    let%test "it works" = assert (2 + 2 = 4)
end)

|}

(** default main.ml file *)
let main_ml =
  {| 
open Base

let main =
  printf "hello world!\n"

let () = main ()
|}

(** default .gitignore file *)
let git_ignore = {| 
  _*

  |}
