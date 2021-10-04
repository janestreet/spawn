#include <sys/types.h>
#include <unistd.h>

#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

#if !defined(_WIN32)

CAMLprim value test_getpgid(value pid)
{
  return Val_int(getpgid(Int_val(pid)));
}

#else

CAMLprim value test_getpgid(value pid)
{
  unix_error(ENOSYS, "getpgid", Nothing);
}

#endif
