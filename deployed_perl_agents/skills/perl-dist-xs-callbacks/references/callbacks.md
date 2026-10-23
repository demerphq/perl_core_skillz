# Callback sequencing and exceptions

## Stack protocol

Use the target Perl's `perlcall` examples and `perlapi` contracts. For the
traditional callback API the sequence is:

1. Obtain interpreter context if the helper does not receive it; declare `dSP`
   when a local stack pointer is needed.
2. `ENTER; SAVETMPS;` to establish the cleanup scope when this call owns one.
3. `PUSHMARK(SP)`, reserve capacity, then push scalar arguments. Supply valid
   lifetimes for every pushed value; a push alone is not an ownership transfer
   that makes arbitrary borrowed data safe.
4. `PUTBACK` before calling Perl so it sees the updated stack position.
5. Invoke `call_sv`, `call_pv`, or `call_method` with deliberate context flags.
6. `SPAGAIN` before accessing results: the stack may have moved. Inspect errors
   if trapping them, then consume the count of returned items on every path.
7. Retain/copy any result or exception needed outside this scope. `POPs` removes
   a stack slot; it does not grant an independently owned reference to its SV.
8. `PUTBACK; FREETMPS; LEAVE;` on the normal path, with resource guards for
   exceptional unwinding.

After any operation that can run Perl, reassess local SP and cached addresses.
Do not cache `SV **` stack-slot addresses across calls. Avoid passing `POPs`
directly to macros that can evaluate arguments more than once on supported
Perls: pop into an `SV *` local and then convert it.

Use `G_SCALAR` for one scalar-context result, `G_LIST` (or the documented name
on supported Perls) for list context, and `G_VOID`/`G_DISCARD` for the appropriate
void/discard policy. `G_DISCARD` changes result handling and temporary behavior;
read its contract. A list-context result can be empty; check the returned count
before popping. `call_method` needs an invocant among the arguments.

## Errors

Without `G_EVAL`, a Perl exception can unwind immediately past native frames.
Use `G_EVAL` when the interface must catch the error to release native resources
or translate it. Do not use it merely to swallow failures.

Inspect `ERRSV` promptly and preserve an error needed after further Perl
execution. Exceptions may be objects, including objects with false boolean
overload; a check solely based on `SvTRUE(ERRSV)` can miss those. Account for
reference-valued errors as well as ordinary error strings, and preserve the
object instead of stringifying it. The trap's return count is not an error
indicator: `G_EVAL|G_SCALAR` can return one undef on failure, which still needs
to be consumed if continuing.

Cleanup and destructors can run Perl and overwrite `$@`; do not hold only a
borrowed alias to `ERRSV` while cleaning up. Arrange ownership for a saved error,
perform cleanup, and use the supported exception propagation mechanism such as
`croak_sv` where available. Define how pre-existing `$@` is preserved or replaced
if that is observable. `G_KEEPERR` is specialized cleanup behavior with warning
semantics, not a drop-in substitute for ordinary trapping and rethrowing.

`eval_pv`'s second argument controls error behavior; do not pass user data as
Perl source or assume it shares `call_sv`'s argument/result protocol. Native
exception macros described in `perlguts` require careful target-specific use;
prefer an established callback/guard pattern rather than inventing a longjmp
handler for an ordinary wrapper.

## Retention and reentry

If registering a callback for later use, retain it before the caller can release
it, replace/release the previous callback predictably, and release it during
the correct interpreter's teardown. A closure may retain the receiver, forming
a cycle. A weak reference is appropriate only when losing the callback or
receiver is part of the documented contract.

Preserve enough state before calling out that the callback can reenter, replace
itself, close its receiver, mutate arguments, or die. Holding an owned reference
keeps a wrapper alive but does not prevent its native handle from being closed.
Validate state again after returning when needed. Never let a Perl exception
jump through native library frames that forbid that control transfer: trap it
at the callback boundary, retain it, return a native error indication, and
propagate it once the library has unwound normally.

Test normal results in requested contexts, empty results, exceptions (including
objects), nested calls, stack growth, temporary results, replacement of a stored
callback, and cleanup after errors. Restrict tests to the behaviors the API
supports, and state unsupported asynchronous/foreign-thread callbacks explicitly.
