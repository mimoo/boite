open Core

(** run a command and return the result *)
let run cmd =
  let inp = Unix.open_process_in cmd in
  let r = In_channel.input_all inp in
  In_channel.close inp;
  String.rstrip r

(** checks if a program exists in the PATH *)
let exists command =
  let res =
    run ("command -v " ^ command ^ " &> /dev/null && echo 'yes' || echo 'no'")
  in
  if String.(res = "yes") then true else false