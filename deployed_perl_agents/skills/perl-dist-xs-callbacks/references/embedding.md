# Embedding an installed Perl

Read `perldoc perlembed` and `perldoc ExtUtils::Embed` for the target build.
This reference is for a host that owns interpreter lifecycle, not an extension
loaded into an existing interpreter.

Obtain compile and link settings from that Perl rather than hard-coding header
paths, `-lperl`, or platform linker flags:

```sh
perl -MExtUtils::Embed -e ccopts
perl -MExtUtils::Embed -e ldopts
```

These commands print toolchain settings; they are not a portable shell argument
parser. Integrate them using the host build system's normal quoting and platform
handling. Some deployed installations lack development headers or a linkable
libperl; identify that as an environment requirement, not a missing core patch.

## Lifecycle and interpreter affinity

Follow the target's process initialization/termination and interpreter
allocation, construction, parsing, running, destruction, and freeing sequence.
Check failure returns and decide when `END` blocks should run. Register static
extensions or DynaLoader bootstrap support where required before parsing code
that needs them. Do not repeatedly run process-wide initialization for every
request in a persistent host.

Keep each Perl-owned value and callback associated with its owning interpreter.
Release native-held SV references while that interpreter is still valid. Do not
share raw SV pointers between interpreters or carry them across destruction.
For multiple interpreters, manage current context using the documented host
pattern; a single cached global interpreter pointer is insufficient.

An interpreter context pointer is not a thread-safety mechanism. Establish
which host thread owns each interpreter and how the host serializes entry.
Foreign library callbacks must obey that policy or marshal work to the owning
thread. Review native-library global state separately from Perl state.

## Persistent hosts

Treat reused interpreters as persistent state: package variables, loaded
modules, callbacks, `%ENV`, directory changes, and retained objects can outlive
a request. Define request isolation and cleanup explicitly. Use callable APIs
instead of constructing source strings with interpolated request data.

Check exception propagation at each host boundary, retaining exception objects
before temporary cleanup and reporting according to the host contract. A fatal
Perl callback must not silently terminate or corrupt an unrelated host request.
Handle PerlIO and stdio through documented interfaces; do not cast between
their opaque stream types.

Validate startup failure, a normal invocation, an exception, repeated requests,
loading an XS dependency, and shutdown. Test multiple interpreters or threading
only when the host promises those modes. A successful stand-alone example
does not prove integration with the host's event loop and lifecycle.
