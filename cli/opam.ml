open Core

(** install opam *)
let install _ =
  ignore
    (Commands.run
       "sh <(curl -sL \
        https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)")

(** check if correct switch installed *)
let check_switch ~ocaml_version =
  let version =
    match Commands.run "ocaml -vnum" |> Semver.of_string with
    | Some v -> v
    | None -> failwith "couldn't parse result of `ocaml -vnum`"
  in
  let ocaml_version = Option.value_exn (Semver.of_string ocaml_version) in
  Semver.compare version ocaml_version = 0

(** create a switch *)
let create_switch ~ocaml_version =
  (* TODO: *)
  ignore (Commands.run "opam switch create . " ^ ocaml_version)

let recreate_switch ~ocaml_version path =
  Sys.remove (Filename.concat path "_opam");
  create_switch ~ocaml_version

(** check if a switch exists *)
let switch_exists_at path =
  let switch_dir = Filename.concat path "_opam" in
  match Sys.file_exists switch_dir with
  | `Yes -> (
      match Sys.is_directory switch_dir with
      | `Yes -> true
      | _ -> failwith "error: an _opam file exists but is not an opam switch")
  | _ -> false

(** set up opam *)
let init ~(ocaml_version : Semver.t) path =
  (* install if opam is not installed *)
  if not (Commands.exists "opam") then (
    printf "opam is not installed, installing...\n";
    install ());

  (* update if opam is too old *)
  let version = Commands.run "opam --version" |> Semver.of_string in
  let version =
    match version with
    | None -> failwith "opam version is unreadable"
    | Some version -> version
  in
  if Semver.compare version Defaults.opam_version < 0 then (
    printf "opam version too old (%s), installing newer version (at least %s)\n"
      (Semver.to_string version)
      (Semver.to_string Defaults.opam_version);
    install ());

  (* check if there's a switch installed and if it's at the right version *)
  (* otherwise create a switch *)
  let ocaml_version = Semver.to_string ocaml_version in
  if not (switch_exists_at path) then (
    printf
      "no local switch for this project, creating a local switch for OCaml \
       version %s\n"
      ocaml_version;
    create_switch ~ocaml_version);
  if not (check_switch ~ocaml_version) then (
    printf
      "local switch is at incorrect version, re-creating switch at version %s\n"
      ocaml_version;
    recreate_switch ~ocaml_version path);
  ()

(** check that a list of dependency is installed at the right version *)
let dependencies _deps = ()
