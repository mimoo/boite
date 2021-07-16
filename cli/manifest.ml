(* open Core *)

(* constants *)

let ocaml_version = "4.12.0"

let dune_version = "2.8.5"

(* boite.toml *)

type package = { name : string; version : string }

type ocaml = { ocaml_version : string; dune_version : string }

type dependency = { version : string; path : string; git : string }

type manifest = {
  package : package;
  ocaml : ocaml;
  dependencies : (string * dependency) list;
  build_dependencies : (string * dependency) list;
}

(* functions *)

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
