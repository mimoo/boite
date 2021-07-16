# Boite

## New

```console
$ boite new --lib path
```

will initialize the path with a `Boite.toml` and a `src/lib.ml`. 
If `--lib` is not set, it'll create a `src/main.ml` instead.
The name of the project will be the same as the path's leaf folder.

## Init

```console
$ boite init --lib name
```

will initialize the current folder with a `Boite.toml` and a `src/lib.ml`
If `--lib` is not set, it'll create a `src/main.ml` instead.

## Build

```console
$ boite build
```

will build the current folder's project. This is what happens:

1. Find and parse `Boite.toml` in the current folder, otherwise abort.
2. Figure out if opam is installed, if not install it.
3. After that, shouldn't we lock _opam so that nobody can delete it while we're doing the rest of the steps?
4. Figure out if a switch with version `ocaml_version` is set up and is at the right version, if not fix this (e.g. `opam switch create ./target 4.12.0`).
5. Figure if every dependency listed in `Boite.toml` is installed at the specified version. If not, install them. If there's any conflict, abort and display a message to the user.
   1. I think for this step we can simply install each of them, if they are already installed then nothing will happen, otherwise they will get installed
6. Figure out if `dune 2.9` is installed
7. Create a temporary `dune-project` and `dune` files in `src`
8. Run `dune build` using the `target/_opam` binaries
9. Delete the `dune` file


At the moment, only a single module (in `src/`) can be built. Ideally, we want:

* submodules, we'd have to generate `dune` file in subfolders for that.
* workspaces, where the root `Boite.toml` lists other subfolders containing a `Boite.toml`

## Check

## Test

## Lint

## Publish

## Doc

## Clean

## Update

## Bench

