# v0.17.0

- Support older GCC like 4.8.5 (#59)

- Fix spawning processes on Windows when environment contains non-ascii
  characters (#58)

- Skip calls to pthread_cancelstate on android, as its not available (#52)

- Fix compatibility with systems that do not define `PIPE_BUF`. Use
  `_POSIX_PIPE_BUF` as a fallback. (#49)

- [haiku] Fix compilation on Haiku OS. The header sys/syscalls.h isn't
  available, neither is pipe2()

- Allow setting the sigprocmask for spawned processes (#32)

# v0.15.1

- [windows] Use the same quoting heuristic as the compiler (#29)

- [windows] Fix compilation on cygwin (#29)

# v0.15.0

- Add support for `setpgid` (#23)

# v0.14.0

- Do not use vfork by default on OSX as it seems broken (#20,
  @jeremiedimino)

- Fix compilation under msvc (#21, @nojb)

# v0.13.0

- Breaking change on Windows: to match the Unix behavior, `prog` is
  interpreted as relative to the directory specified by the `cwd`
  argument (#13)

- Switch to dune (#12)

- Switch to MIT+DCO (#11)

# v0.12.0

- Breaking change: make environments abstract so that we can later
  optimize them without further breaking changes (#3)

# v0.11.1

- Fix linking errors due to missing `-lphtread` (#1)

# v0.9.0

Initial release
