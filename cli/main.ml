open Cmdliner

(* common between [new] and [init] *)

let is_lib = Arg.(value & flag & info [ "lib" ])

let new_project is_lib path =
  Format.printf "this is the path: %s, is it a lib? %B\n" path is_lib

(* new *)

let new_term =
  let doc = "initialize a project in a path" in
  Term.info "new" ~doc ~exits:Term.default_exits

let path = 
  let doc = "The path to the project to create." in
  Arg.(required & pos 0 (some string) None & info [ ] ~docv:"PATH" ~doc)

let new_t = Term.(const new_project $ is_lib $ path)

let new_cmd = (new_t, new_term)

(* init *)

let init =
  let doc = "initialize a project in the current dir" in
  Term.info "init" ~doc ~exits:Term.default_exits

let new_project_wrap is_lib =
  let path = Sys.getcwd () in
  new_project is_lib path

let init_t = Term.(const new_project_wrap $ is_lib)

let init_cmd = (init_t, init)

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

let () = Term.exit @@ Term.eval_choice boite_cmd [ init_cmd; new_cmd ]
