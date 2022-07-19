open StdLabels

let run cmd args =
  (* broken when arguments contain spaces but it's good enough for now. *)
  let cmd = String.concat ~sep:" " (cmd :: args) in
  match Sys.command cmd with
  | 0 -> ()
  | n ->
    Printf.eprintf "'%s' failed with code %d" cmd n;
    exit n

let opam args = run "opam" args

let build () =
  opam [ "install"; "."; "--deps-only"; "--with-test" ]

let test () =
  run "dune" [ "runtest" ]

let fmt () =
  let version_of_ocamlformat =
    let ic = open_in ".ocamlformat" in
    let v = Scanf.sscanf (input_line ic) "version=%s" (fun x -> x) in
    close_in ic;
    v
  in
  opam [ "install"; "ocamlformat." ^ version_of_ocamlformat ];
  run "dune" [ "build"; "@fmt" ]

let () =
  match Sys.argv with
  | [| _; "build" |] -> build ()
  | [| _; "test" |] -> test ()
  | [| _; "fmt" |] -> fmt ()
  | _ ->
    prerr_endline "Usage: ci.ml [ build | test | fmt ]";
    exit 1
