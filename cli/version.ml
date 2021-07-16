(* Versions of OCaml and of opam packages make no sense.
 * For some reason they didn't use semver.
 *)

open Core

type version = { major : int; minor : int; patch : int }

type t = { str : string; version : version }

(** parse a [string] into a [t] *)
let of_string str =
  let s = String.split ~on:'.' str in

  (* parse *)
  let (major, minor, patch) : string * string * string =
    match s with
    | [ major; minor ] -> (major, minor, "0")
    | [ major; minor; patch ] -> (major, minor, patch)
    | _ -> failwith "unimplemented"
  in

  (* major *)
  let first_char = String.get major 0 in
  let major =
    if Char.(first_char = 'v') then Str.string_after major 1 else major
  in
  let major = int_of_string major in

  (* minor *)
  let minor = int_of_string minor in

  (* patch *)
  let patch = int_of_string patch in

  (* return *)
  let version = { major; minor; patch } in
  { str; version }

let to_string t = t.str

let compare (t1 : t) (t2 : t) : int =
  let res = Int.compare t1.version.major t2.version.major in
  if res <> 0 then res
  else
    let res = Int.compare t1.version.minor t2.version.minor in
    if res <> 0 then res
    else
      let res = Int.compare t1.version.patch t2.version.patch in
      if res <> 0 then res else 0

let ( > ) t1 t2 = compare t1 t2 > 0

let ( >= ) t1 t2 = compare t1 t2 >= 0

let ( = ) t1 t2 = compare t1 t2 = 0

let ( < ) t1 t2 = compare t1 t2 < 0

let ( <= ) t1 t2 = compare t1 t2 <= 0
