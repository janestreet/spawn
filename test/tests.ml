
let () =
  let ocaml_version = Scanf.sscanf Sys.ocaml_version "%u.%u" (fun a b -> a, b) in
  (* The exception printer for unix errors was only added to 4.11 on Windows *)
  if Sys.win32 && ocaml_version < (4, 11) then
    Printexc.register_printer
      (function
        | Unix.Unix_error (e, s, s') ->
          (match
             (match e with
              | ENOENT -> Some "ENOENT"
              | ENOTDIR -> Some "ENOTDIR"
              | EUNKNOWNERR x -> Some (Printf.sprintf "EUNKNOWNERR %d" x)
              | _ -> None)
           with
           | None -> None
           | Some e ->
             Some (Printf.sprintf "Unix.Unix_error(Unix.%s, %S, %S)" e s s'))
        | _ -> None)

let show_raise f =
  try
    ignore (f () : int)
  with exn ->
    let exn =
      match exn with
      | Unix.Unix_error (err, _func_name, arg) ->
        (* Hide the function name to make the test more portable. On
           Windows, the function is always "CreateProcess" but on Unix
           it might be "execve", "chdir", ... *)
        Unix.Unix_error (err, "<hidden-function-name>", arg)
      | exn -> exn
    in
    Printf.printf "raised %s" (Printexc.to_string exn)

let%expect_test "non-existing program" =
  show_raise (fun () ->
    Spawn.spawn () ~prog:"/doesnt-exist" ~argv:["blah"]);
  [%expect {|
    raised Unix.Unix_error(Unix.ENOENT, "<hidden-function-name>", "/doesnt-exist")
  |}]

let%expect_test "non-existing dir" =
  show_raise (fun () ->
    Spawn.spawn () ~prog:"/bin/true" ~argv:["true"]
      ~cwd:(Path "/doesnt-exist"));
  [%expect {|
    raised Unix.Unix_error(Unix.ENOENT, "<hidden-function-name>", "/doesnt-exist")
  |}]

let wait pid =
  match snd (Unix.waitpid [] pid) with
  | WEXITED   0 -> ()
  | WEXITED   n -> Printf.ksprintf failwith "exited with code %d" n
  | WSIGNALED n -> Printf.ksprintf failwith "got signal %d" n
  | WSTOPPED  _ -> assert false

let%expect_test "cwd:Fd" =
  if Sys.win32 then
    print_string "/tmp"
  else begin
    let fd = Unix.openfile "/tmp" [O_RDONLY] 0 in
    wait (Spawn.spawn () ~prog:"/bin/pwd" ~argv:["pwd"] ~cwd:(Fd fd));
    Unix.close fd
  end;
  [%expect {|
    /tmp
  |}]

let%expect_test "cwd:Fd (invalid)" =
  show_raise (fun () ->
    if Sys.win32 then
      raise (Unix.Unix_error(ENOTDIR, "fchdir", ""))
    else
      Spawn.spawn () ~prog:"/bin/pwd" ~argv:["pwd"] ~cwd:(Fd Unix.stdin));
  [%expect {|
    raised Unix.Unix_error(Unix.ENOTDIR, "<hidden-function-name>", "")
  |}]


module Program_lookup = struct
  let path_sep = if Sys.win32 then ';'    else ':'
  let exe_ext  = if Sys.win32 then ".exe" else ""

  let split_path s =
    let rec loop i j =
      if j = String.length s then
        [String.sub s i (j - i)]
      else if s.[j] = path_sep then
        String.sub s i (j - i) :: loop (j + 1) (j + 1)
      else
        loop i (j + 1)
    in
    loop 0 0

  let path =
    match Sys.getenv "PATH" with
    | exception Not_found -> []
    | s -> split_path s

  let find_prog prog =
    let rec search = function
      | [] -> Printf.ksprintf failwith "Program %S not found in PATH!" prog
      | dir :: rest ->
        let fn = Filename.concat dir prog ^ exe_ext in
        if Sys.file_exists fn then
          fn
        else
          search rest
    in
    search path
end

let%expect_test "inheriting stdout with close-on-exec set" =
  (* CR-soon jdimino for jdimino: the test itself seems to pass,
     however there seem to be another issue related to ppx_expect and
     Windows. *)
  if Sys.win32 then
    print_string "hello world"
  else begin
    Unix.set_close_on_exec Unix.stdout;
    let shell, arg =
      if Sys.win32 then
        "cmd", "/c"
      else
        "sh", "-c"
    in
    let prog = Program_lookup.find_prog shell in
    wait (Spawn.spawn () ~prog ~argv:[shell; arg; {|echo "hello world"|}]);
  end;
  [%expect {| hello world |}]

let%expect_test "prog relative to cwd" =
  if Sys.win32 then
    print_string "Hello, world!"
  else
    wait (Spawn.spawn () ~prog:"./hello.exe" ~argv:["hello"] ~cwd:(Path "exe"));
  [%expect {| Hello, world! |}]
