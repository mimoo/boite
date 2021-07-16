open Core

(* boite.toml *)

type package = { name : string; version : Semver.t }

type ocaml = { ocaml_version : Semver.t; dune_version : Semver.t option }

type dependency = {
  version : Semver.t;
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

  (** convert a [string] to a [Semver.t] *)
  let to_semver s =
    match Semver.of_string s with
    | Some x -> x
    | None ->
        printf "could not parse semver string '%s'\n" s;
        failwith "error"

  (* toml stuff *)
  open Toml.Types

  let get_table table key =
    match Table.find_opt (Table.Key.of_string key) table with
    | Some (TTable t) -> t
    | None | _ ->
        printf "key %s should be of type string\n" key;
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
    match table with Some (TString s) -> Some s | _ -> None
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
  let version = Utils.get_string package ~key:"version" |> Utils.to_semver in
  let package = { name; version } in

  (* parse ocaml *)
  let ocaml = Utils.get_table manifest "ocaml" in
  let ocaml_version =
    Utils.get_string ocaml ~key:"ocaml_version" |> Utils.to_semver
  in
  let dune_version = Utils.get_string_opt ocaml ~key:"dune_version" in
  let dune_version = Option.map dune_version ~f:Utils.to_semver in
  let ocaml = { ocaml_version; dune_version } in

  (* parsing dependencies *)
  (*
  let parse manifest dependencies =
    let deps = Toml.Types.Table.find (Toml.Min.key dependencies) manifest in
    let version = Utils.get_string deps ~key:"version" in
    let path = Utils.get_string_opt deps ~key:"path" in
    let git = Utils.get_string_opt deps ~key:"git" in
    *)
  {
    package;
    ocaml;
    dependencies = [];
    dev_dependencies = [];
    build_dependencies = [];
  }

(*
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
