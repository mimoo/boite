open Core
open Cmdliner

(* common between [new] and [init] *)

let is_lib = Arg.(value & flag & info [ "lib" ])

let init_folder is_lib path =
  printf "%B %s" is_lib path;
  (* create boite.toml *)
  failwith "unimplemented"

let new_project is_lib path =
  let is_directory = Sys.is_directory path in
  printf "this is the path: %s, is it a lib? %B\n" path is_lib;
  let is_initialized = match is_directory with 
    | `Yes -> true
    | _ -> false
  in
  if is_initialized then 
    printf "%s is already a directory\n" path
  else
    (* create dir *)
    Unix.mkdir_p path;
    init_folder is_lib path

(* new *)

module New = struct 
  let info =
    let doc = "initialize a project in a path" in
    Term.info "new" ~doc ~exits:Term.default_exits

  let path = 
    let doc = "The path to the project to create." in
    Arg.(required & pos 0 (some string) None & info [ ] ~docv:"PATH" ~doc)

  let term = Term.(const new_project $ is_lib $ path)

  let cmd = (term, info)
end

(* init *)

module Init = struct 
  let info =
    let doc = "initialize a project in the current dir" in
    Term.info "init" ~doc ~exits:Term.default_exits

  let new_project_wrap is_lib =
    let path = Sys.getcwd () in
    new_project is_lib path

  let term = Term.(const new_project_wrap $ is_lib)

  let cmd = (term, info)
end

(* boite *)

let boite =
  let doc = "initializes a new OCaml project" in
  Term.info "boite" ~version:"%‌%VERSION%%" ~doc ~exits:Term.default_exits

let revolt () =
  print_endline
    "Common boite commands are: \n\
     \tbuild\n\
     \tcheck\n\
     \tclean\n\
     \tdoc\n\
     \tnew\n\
     \tinit\n\
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

let () = Term.exit @@ Term.eval_choice boite_cmd [ Init.cmd; New.cmd ]
