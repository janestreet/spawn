open! Core
open Expect_test_helpers_kernel

let _ = ignore (Unix.Unix_error (ENOENT, "", ""))

let%expect_test "non-existing program" =
  show_raise (fun () ->
    Spawn.spawn () ~prog:"/doesnt-exist" ~argv:["blah"]);
  [%expect {|
    (raised (Unix.Unix_error "No such file or directory" execve /doesnt-exist))
  |}]

let%expect_test "non-existing dir" =
  show_raise (fun () ->
    Spawn.spawn () ~prog:"/bin/true" ~argv:["true"] ~cwd:(Path "/doesnt-exist"));
  [%expect {|
    (raised (Unix.Unix_error "No such file or directory" chdir /doesnt-exist))
  |}]

let wait n =
  Pid.of_int n
  |> Unix.waitpid
  |> Unix.Exit_or_signal.or_error
  |> ok_exn

let%expect_test "cwd:Fd" =
  let fd = Unix.openfile "/tmp" ~mode:[O_RDONLY] in
  Spawn.spawn () ~prog:"/bin/pwd" ~argv:["pwd"] ~cwd:(Fd fd)
  |> wait;
  Unix.close fd;
  [%expect {|
    /tmp
  |}]

let%expect_test "cwd:Fd (invalid)" =
  show_raise (fun () ->
    Spawn.spawn () ~prog:"/bin/pwd" ~argv:["pwd"] ~cwd:(Fd Unix.stdin));
  [%expect {|
    (raised (Unix.Unix_error "Not a directory" fchdir ""))
  |}]
