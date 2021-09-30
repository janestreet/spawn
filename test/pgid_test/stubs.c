#include <sys/types.h>
#include <unistd.h>

#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

CAMLprim value test_getpgid(value pid)
{
  return Val_int(getpgid(Int_val(pid)));
}
