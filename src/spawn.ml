open StdLabels

module Working_dir = struct
  type t =
    | Path of string
    | Fd of Unix.file_descr
    | Inherit
end

module Unix_backend = struct
  type t =
    | Fork
    | Vfork

  let default =
    match Sys.getenv "SPAWN_USE_FORK" with
    | _                   -> Fork
    | exception Not_found -> Vfork
end

external spawn_unix
  :  env:string list option
  -> cwd:Working_dir.t
  -> prog:string
  -> argv:string list
  -> stdin:Unix.file_descr
  -> stdout:Unix.file_descr
  -> stderr:Unix.file_descr
  -> use_vfork:bool
  -> int
  = "spawn_unix_byte" "spawn_unix"

external spawn_windows
  :  env:string option
  -> cwd:string option
  -> prog:string
  -> cmdline:string
  -> stdin:Unix.file_descr
  -> stdout:Unix.file_descr
  -> stderr:Unix.file_descr
  -> int
  = "spawn_windows_byte" "spawn_windows"

let windows_env env =
  let len =
    List.fold_left env ~init:1 ~f:(fun acc s ->
      acc + String.length s + 1)
  in
  let buf = Buffer.create len in
  List.iter env ~f:(fun s ->
    Buffer.add_string buf s;
    Buffer.add_char buf '\000');
  Buffer.add_char buf '\000';
  Buffer.contents buf

let spawn_windows ~env ~cwd ~prog ~argv ~stdin ~stdout ~stderr ~use_vfork:_ =
  let cwd =
    match (cwd : Working_dir.t) with
    | Path p -> Some p
    | Fd _ ->
      invalid_arg "Spawn.spawn: [cwd=Fd _] is not supported on Windows"
    | Inherit -> None
  in
  let env = match env with None -> None | Some env -> Some (windows_env env) in
  let cmdline =
    String.concat (List.map argv ~f:Filename.quote) ~sep:" "
  in
  spawn_windows ~env ~cwd ~prog ~cmdline ~stdin ~stdout ~stderr

let no_null s =
  if String.contains s '\000' then
    Printf.ksprintf invalid_arg
      "Spawn.spawn: NUL bytes are not allowed in any of the arguments \
       but found one in %S"
      s

let spawn ?env ?(cwd=Working_dir.Inherit) ~prog ~argv
      ?(stdin=Unix.stdin) ?(stdout=Unix.stdout) ?(stderr=Unix.stderr)
      ?(unix_backend=Unix_backend.default) () =
  (match cwd with Path s -> no_null s | Fd _ | Inherit -> ());
  no_null prog;
  List.iter argv ~f:no_null;
  (match env with None -> () | Some l -> List.iter l ~f:no_null);
  let backend =
    if Sys.win32 then
      spawn_windows
    else
      spawn_unix
  in
  let use_vfork =
    match unix_backend with
    | Vfork -> true
    | Fork  -> false
  in
  backend ~env ~cwd ~prog ~argv ~stdin ~stdout ~stderr ~use_vfork

external safe_pipe : unit -> Unix.file_descr * Unix.file_descr = "spawn_pipe"

let safe_pipe =
  if Sys.win32 then
    fun () ->
      (* CR-someday jdimino: fix race conditions on Windows *)
      let fdr, fdw = Unix.pipe () in
      match
        Unix.set_close_on_exec fdr;
        Unix.set_close_on_exec fdw
      with
      | () -> (fdr, fdw)
      | exception exn ->
        (try Unix.close fdr with _ -> ());
        (try Unix.close fdw with _ -> ());
        raise exn
  else
    safe_pipe
