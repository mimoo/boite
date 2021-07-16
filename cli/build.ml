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
  let cmd = "opam switch create . ocaml-base-compiler." ^ ocaml_version in
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
  let version = Commands.run "opam --version" |> Version.of_string in
  if Version.(version < Defaults.opam_version) then (
    printf "opam version too old (%s), installing newer version (at least %s)\n"
      version.str Defaults.opam_version.str;
    install ());

  (* check if there's a switch installed, otherwise create a switch *)
  let switch_dir = FilePath.concat path "_opam" in
  if not (switch_exists_at switch_dir) then (
    printf
      "no local switch for this project, creating a local switch for OCaml \
       version %s\n\
       %!"
      (Ocaml_version.to_string ocaml_version);
    create_switch ~ocaml_version);

  (* check if the local switch is at the right version *)
  if not (check_switch ~ocaml_version) then (
    printf
      "local switch is at incorrect version, re-creating switch at version %s\n\
       %!"
      (Ocaml_version.to_string ocaml_version);
    recreate_switch ~ocaml_version switch_dir);

  (* *)
  ()

(** list the dependencies installed *)
let list_dependencies () =
  (* use opam list to get list of installed dependencies *)
  let installed =
    Commands.run
      "opam list \
       --columns='name,installed-version,version,package,source-hash,pin,available-versions,depexts,vc-ref'"
  in
  (* get rid of table headers *)
  let installed = String.split_lines installed in
  let installed =
    List.filter installed ~f:(fun x -> Char.(String.get x 0 <> '#'))
  in
  installed

(** install a dependency *)
let install_dependency (name, Manifest.{ version; path; git }) =
  let res =
    match (version, path, git) with
    (* if only a version is set, install via opam *)
    | Some v, None, None ->
        let cmd = "opam install " ^ name ^ "." ^ v.str in
        printf "%s\n" cmd;
        Commands.run cmd
    (* if a path is set, pin the path *)
    | _, Some p, None -> Commands.run "opam pin add -k path " ^ p
    (* if a git repo is set, pin the repo *)
    | _, None, Some g -> Commands.run "opam pin add git+" ^ g
    (* otherwise just fail miserably *)
    | _ ->
        printf "couldn't install %s\n" name;
        failwith "couldn't install dependency"
  in
  ignore res

let build path =
  (* find boite.toml *)
  let manifest = Manifest.parse_manifest "Boite.toml" in

  (* make sure opam is installed *)
  let ocaml_version = manifest.ocaml.ocaml_version in
  init ~ocaml_version path;

  (* check that we have all dependencies *)
  List.iter manifest.dependencies ~f:install_dependency;

  (* create dune-project *)

  (* create dune file *)
  printf "built\n"
