open Core

(* boite.toml *)

type package = { name : string; version : Version.t }

type ocaml = {
  ocaml_version : Ocaml_version.t;
  dune_version : Version.t option;
}

type dependency = {
  version : Version.t option;
  path : string option;
  git : string option;
}

type manifest = {
  package : package;
  ocaml : ocaml;
  dependencies : (string * dependency) list;
  dev_dependencies : (string * dependency) list;
  build_dependencies : (string * dependency) list;
}

(* toml stuff *)

module Utils = struct
  (* semver stuff *)

  (* convert a [string] to a [Semver.t] *)
  (*
  let to_semver s =
    match Semver.of_string s with
    | Some x -> x
    | None ->
        printf "could not parse semver string '%s'\n" s;
        failwith "error"
  *)

  (* toml stuff *)
  open Toml.Types

  let get_table table key =
    match Table.find_opt (Table.Key.of_string key) table with
    | Some (TTable t) -> t
    | None | _ ->
        printf "key %s should be of type string\n" key;
        failwith "error parsing toml file"

  let get_table_opt table key =
    match Table.find_opt (Table.Key.of_string key) table with
    | Some (TTable t) -> Some t
    | None -> None
    | _ ->
        printf "key %s is not a table\n" key;
        failwith "error parsing toml file"

  let get_string table ~(key : string) : string =
    let table = Table.find_opt (Table.Key.of_string key) table in
    match table with
    | Some (TString s) -> s
    | None | _ ->
        printf "key %s should be of type string\n" key;
        failwith "error parsing toml file"

  let get_string_opt table ~(key : string) : string option =
    let table = Table.find_opt (Table.Key.of_string key) table in
    match table with
    | Some (TString s) -> Some s
    | None -> None
    | _ ->
        printf "couldn't get string from key %s\n" key;
        failwith "error parsing toml file"
end

(* functions *)

let parse_manifest filename =
  (* parse toml *)
  let manifest =
    match Toml.Parser.from_filename filename with
    | `Error (err, loc) ->
        printf "%s, in file %s at line %d\n" err loc.source loc.line;
        failwith "error"
    | `Ok res -> res
  in
  (* parse package *)
  let package = Utils.get_table manifest "package" in
  let name = Utils.get_string package ~key:"name" in
  let version = Utils.get_string package ~key:"version" |> Version.of_string in
  let package = { name; version } in

  (* parse ocaml *)
  let ocaml = Utils.get_table manifest "ocaml" in
  let ocaml_version =
    Utils.get_string ocaml ~key:"ocaml_version" |> Ocaml_version.of_string_exn
  in
  let dune_version = Utils.get_string_opt ocaml ~key:"dune_version" in
  let dune_version = Option.map dune_version ~f:Version.of_string in
  let ocaml = { ocaml_version; dune_version } in

  (* parsing a single dependency *)
  let parse_dep (name, dep_info) =
    (* name *)
    let name = Toml.Types.Table.Key.to_string name in
    match dep_info with
    (* value is either of the form dep = "0.1.0" *)
    | Toml.Types.TString version ->
        let version = Some (Version.of_string version) in
        (name, { version; path = None; git = None })
    (* or of the form dep = { version = "0.1.0", path = "..."} *)
    | Toml.Types.TTable tbl ->
        let version =
          Utils.get_string_opt tbl ~key:"version"
          |> Option.map ~f:Version.of_string
        in
        let path = Utils.get_string_opt tbl ~key:"path" in
        let git = Utils.get_string_opt tbl ~key:"git" in
        if Option.is_some path && Option.is_some git then (
          printf "dependency %s has a path and a git, invalid\n" name;
          failwith "error while parsing Boite.toml");
        if Option.is_none version && Option.is_none git && Option.is_none path
        then (
          printf "dependency %s needs to have a version, a path, or a git\n"
            name;
          failwith "error while parsing Boite.toml");
        (name, { version; path; git })
    | _ ->
        printf "dependency %s is not defined correctly\n" name;
        failwith "error while parsing Boite.toml"
  in
  (* parsing dependencies *)
  let parse_deps table dependencies =
    let deps = Utils.get_table_opt table dependencies in
    let deps = Option.map ~f:Toml.Types.Table.bindings deps in
    match deps with Some d -> List.map ~f:parse_dep d | None -> []
  in
  let dependencies = parse_deps manifest "dependencies" in
  let dev_dependencies = parse_deps manifest "dev_dependencies" in
  let build_dependencies = parse_deps manifest "build_dependencies" in
  { package; ocaml; dependencies; dev_dependencies; build_dependencies }

(* writing manifest files
let create_manifest name =
  let package = { name; version = "0.1.0" } in
  let ocaml = { ocaml_version; dune_version } in
  { package; ocaml; dependencies = []; build_dependencies = [] }

let write_to_file (manifest : manifest) path =
  let package =
    Toml.Min.of_key_values
      [
        (Toml.Min.key "name", Toml.Types.TString manifest.package.name);
        (Toml.Min.key "version", Toml.Types.TString manifest.package.version);
      ]
  in
  let ocaml =
    Toml.Min.of_key_values
      [
        ( Toml.Min.key "ocaml_version",
          Toml.Types.TString manifest.ocaml.ocaml_version );
        ( Toml.Min.key "dune_version",
          Toml.Types.TString manifest.ocaml.dune_version );
      ]
  in
  let dependencies_to_toml (name, dependency) =
    ( Toml.Min.key name,
      Toml.Types.TTable
        (Toml.Min.of_key_values
           [
             (Toml.Min.key "version", Toml.Types.TString dependency.version);
             (Toml.Min.key "path", Toml.Types.TString dependency.path);
             (Toml.Min.key "git", Toml.Types.TString dependency.git);
           ]) )
  in
  let dependencies = List.map manifest.dependencies ~f:dependencies_to_toml in
  let dependencies = Toml.Min.of_key_values dependencies in
  let build_dependencies =
    List.map manifest.build_dependencies ~f:dependencies_to_toml
  in
  let build_dependencies = Toml.Min.of_key_values build_dependencies in
  let toml_data =
    Toml.Min.of_key_values
      [
        (Toml.Min.key "package", Toml.Types.TTable package);
        (Toml.Min.key "ocaml", Toml.Types.TTable ocaml);
        (Toml.Min.key "dependencies", Toml.Types.TTable dependencies);
        (Toml.Min.key "build_dependencies", Toml.Types.TTable build_dependencies);
      ]
  in
  let data = Toml.Printer.string_of_table toml_data in
  Out_channel.write_all path ~data

  *)
