open Core

(** install opam *)
let install _ =
  ignore
    (Commands.run
       "sh <(curl -sL \
        https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)")

(** check if correct switch installed *)
let check_switch ~ocaml_version =
  let version = Commands.run "ocaml -vnum" |> Ocaml_version.of_string_exn in
  Ocaml_version.compare version ocaml_version = 0

(** create a switch *)
let create_switch ~ocaml_version =
  let ocaml_version = Ocaml_version.to_string ocaml_version in
  let cmd = "opam switch create . " ^ ocaml_version in
  printf "running: %s\n%!" cmd;
  ignore (Commands.run cmd)

let recreate_switch ~ocaml_version switch_dir =
  FileUtil.rm ~recurse:true [ switch_dir ];
  create_switch ~ocaml_version

(** check if a switch exists *)
let switch_exists_at switch_dir =
  match Sys.file_exists switch_dir with
  | `Yes -> (
      match Sys.is_directory switch_dir with
      | `Yes -> true
      | _ -> failwith "error: an _opam file exists but is not an opam switch")
  | _ -> false

(** set up opam *)
let init ~(ocaml_version : Ocaml_version.t) path =
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
  let switch_dir = FilePath.concat path "_opam" in
  if not (switch_exists_at switch_dir) then (
    printf
      "no local switch for this project, creating a local switch for OCaml \
       version %s\n\
       %!"
      (Ocaml_version.to_string ocaml_version);
    create_switch ~ocaml_version);
  if not (check_switch ~ocaml_version) then (
    printf
      "local switch is at incorrect version, re-creating switch at version %s\n\
       %!"
      (Ocaml_version.to_string ocaml_version);
    recreate_switch ~ocaml_version switch_dir);
  ()

(** check that a list of dependency is installed at the right version *)
let dependencies _deps = ()
