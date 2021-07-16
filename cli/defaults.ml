let manifest =
  {|
[package]
name = "{{name}}"
version = "0.1.0"

[ocaml]
ocaml_version = "4.12.0"

# your dependencies go here
[dependencies]
base = "0.14.1"

|}

let lib_ml =
  {| 
open Base

let%test_module _ = (module struct
    let%test "it works" = assert (2 + 2 = 4)
end)

|}

let main_ml =
  {| 
open Base

let main =
  printf "hello world!\n"

let () = main ()
|}
