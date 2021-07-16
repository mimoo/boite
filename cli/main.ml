open Core
open Cmdliner

(* common between [new] and [init] *)

let is_lib = Arg.(value & flag & info [ "lib" ])

let new_project ~is_lib ?name path =
  let is_directory = Sys.is_directory path in
  printf "this is the path: %s, is it a lib? %B\n" path is_lib;
  let is_initialized = match is_directory with `Yes -> true | _ -> false in

  (* create dir if it doesn't exist *)
  if not is_initialized then Unix.mkdir_p path;

  (* abort if there's any file in the folder *)
  if Array.length (Sys.readdir path) > 0 then (
    printf "aborting, folder already initialized\n";
    failwith "error");

  (* initialize git repo, or abort if already done *)
  ignore (Commands.run "git init");

  (* create .gitignore *)
  let git_ignore_path = Filename.concat path ".gitignore" in
  Out_channel.write_all git_ignore_path ~data:Defaults.git_ignore;

  (* figure out project name *)
  let name =
    match name with
    | None -> Filename.realpath path |> Filename.basename
    | Some name -> name
  in

  (* create boite.toml *)
  let data = Defaults.manifest in
  let data = String.substr_replace_first data ~pattern:"{{name}}" ~with_:name in
  let manifest_path = Filename.concat path "Boite.toml" in
  Out_channel.write_all manifest_path ~data;

  (* create src dir *)
  let src_path = Filename.concat path "src" in
  Unix.mkdir_p src_path;

  (* create ml file *)
  let path, data =
    if is_lib then (Filename.concat src_path "lib.ml", Defaults.lib_ml)
    else (Filename.concat src_path "main.ml", Defaults.main_ml)
  in
  Out_channel.write_all path ~data

(* new *)

module New = struct
  let info =
    let doc = "initialize a project in a path" in
    Term.info "new" ~doc ~exits:Term.default_exits

  let path =
    let doc = "The path to the project to create." in
    Arg.(required & pos 0 (some string) None & info [] ~docv:"PATH" ~doc)

  let new_project_wrap is_lib path = new_project ~is_lib path

  let term = Term.(const new_project_wrap $ is_lib $ path)

  let cmd = (term, info)
end

(* init *)

module Init = struct
  let info =
    let doc = "initialize a project in the current dir" in
    Term.info "init" ~doc ~exits:Term.default_exits

  let new_project_wrap is_lib name =
    let path = Sys.getcwd () in
    new_project ~is_lib ~name path

  let project_name =
    let doc = "The name of your project." in
    Arg.(value & pos 0 string "my_lib" & info [] ~docv:"NAME" ~doc)

  let term = Term.(const new_project_wrap $ is_lib $ project_name)

  let cmd = (term, info)
end

(* build *)

module Build = struct
  let info =
    let doc = "build the project contained in the current dir" in
    Term.info "build" ~doc ~exits:Term.default_exits

  let path =
    let doc = "The path to the project to create." in
    Arg.(value & pos 0 string "." & info [] ~docv:"PATH" ~doc)

  let term = Term.(const Build.build $ path)

  let cmd = (term, info)
end

(* boite *)

let boite =
  let doc = "initializes a new OCaml project" in
  Term.info "boite" ~version:"%‌%VERSION%%" ~doc ~exits:Term.default_exits

let revolt () =
  print_endline
    "Common boite commands are: \n\
     \tbuild (WIP)\n\
     \tcheck\n\
     \tclean\n\
     \tdoc\n\
     \tnew (works)\n\
     \tinit (works)\n\
     \trun\n\
     \ttest\n\
     \tbench\n\
     \tupdate\n\
     \tsearch\n\
     \tpublish\n\
     \tinstall\n\
     \tuninstall"

let boite_t = Term.(const revolt $ const ())

let boite_cmd = (boite_t, boite)

(* ... *)

let () =
  Term.exit @@ Term.eval_choice boite_cmd [ Init.cmd; New.cmd; Build.cmd ]
