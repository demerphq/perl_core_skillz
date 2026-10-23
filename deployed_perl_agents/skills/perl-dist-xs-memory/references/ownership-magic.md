# Ownership, cleanup, and magic

## Make an ownership ledger

For each value record: where it came from, whether this code owns a reference,
who takes that reference next, and what happens on an error. Explain transfers
in comments where the C statements alone hide them.

| Operation | Ownership consequence |
| --- | --- |
| `newSV*`, `newAV`, `newHV` | Normally returns a new value with one reference owned by the caller; inspect specialized constructors. |
| Argument `SV *`, `ST(i)`, `SvRV`, ordinary container fetch | Normally borrowed; do not release or transfer the owner's reference. Observe exact API and magic behavior. |
| `SvREFCNT_inc(sv)` | Creates another owned reference to the same SV, not a value snapshot. |
| `newSVsv(sv)` | Creates a new scalar value; references inside it still refer to the same referents. It is not a recursive deep copy. |
| `newRV_inc(sv)` / `newRV(sv)` | New RV owns an added reference; the caller still owns any reference it held before. |
| `newRV_noinc(sv)` | New RV takes an existing owned reference; do not decrement that transferred reference. |
| `sv_2mortal(sv)` | Transfers one owned reference to the temps stack for a later decrement; does not increment it. |
| `SvREFCNT_dec(sv)` | Releases one owned reference; final release may run Perl destructors and other cleanup. |

Do not decrement a borrowed value to balance somebody else's increment. Do
not mortalize the same ownership obligation twice. A mortal value may still
have independent owned references; reason about those references separately.

The normal `SV *` XSUB output mortalizes an owned return reference. Include
that implicit transfer in the ledger. Custom typemaps and AV/HV reference
typemaps can change the calculation: inspect generated C rather than applying
one rule to every pointer return.

## Containers

For ordinary arrays and hashes, `av_fetch`/`hv_fetch` can return NULL; test
before dereferencing `SV **`. An absent element and an existing undef element
are distinguishable. `lval` fetches can create entries, so do not use them for
read-only inspection. Empty arrays have a last index of -1; keep index types
signed when a negative sentinel is possible.

A successful ordinary `av_store`, `hv_store`, or `hv_store_ent` takes one
reference to the supplied value without adding one. Supply a new owned value
or increment a borrowed value before passing ownership. For APIs returning
NULL without retaining it, release that still-owned reference. Do not flatten
this into a generic “NULL means allocation failure” rule: tied containers can
return NULL for other reasons.

Read the exact target documentation for tied container access. A fetch/store
may arrange element magic rather than perform all Perl-level `FETCH`/`STORE`
work immediately. Scalar get/set magic is relevant too. Test tied semantics
through the public API rather than assuming an ordinary-container recipe is
sufficient. Fast `*_simple` APIs have stronger preconditions and may be absent
on supported Perls; use them only when those conditions are established.

Do not retain an `SV **` slot pointer across operations that can resize or
mutate its container. Retain the SV separately if it must survive mutation,
and re-fetch slots when needed. Hash iteration state can be disturbed by nested
iteration or callbacks; do not expose an iteration strategy that assumes users
cannot reenter it.

## Cleanup across errors

Perl conversions, memory allocations, magic, callbacks, warnings configured as
fatal, and destructors can croak. Any C resource still owned at that point
needs an unwind plan. Acquire after validation where possible; use a suitable
Perl-owned guard or documented save-stack cleanup in a valid dynamic scope
when later work can throw. Consult `SAVEDESTRUCTOR_X`, `SAVEFREESV`, and related
entries for the target Perl before registering cleanup. Save-stack cleanup
and mortal cleanup have different boundaries; neither should be registered
twice for the same ownership obligation.

`ENTER`/`LEAVE` delimit dynamic scopes; `SAVETMPS`/`FREETMPS` delimit temporary
cleanup within them. A result that will be used after temporary cleanup needs
an independent reference or copy before cleanup. Do not insert a new temps
scope and then return its already-freed mortal.

The generated `CLEANUP:` section runs after normal output conversion. It will
not run when an earlier input/output conversion or `CODE:` croaks, nor after
an early `XSRETURN_*`. A manual `free` after a throwing operation is similarly
insufficient. Match allocators: `Newx`/`Newxz`/`Renew` with `Safefree`, library
allocations with that library's release operation. Check multiplication and
addition for overflow before allocating from user-controlled counts.

## Magic and reentry

Use `perlapi` to distinguish a function's source get magic from destination
set magic. For example, `sv_setsv` gets source magic but does not set destination
magic; `sv_setsv_mg` does both. Ordinary `sv_setpvn` does not invoke set magic.
Use the appropriate `_mg` form or a deliberate `SvSETMAGIC` after the write,
without invoking it twice through generated output code too.

If checks require a fetched magical value, arrange one intentional get and use
compatible no-magic operations for subsequent checks/conversion. Do not simply
add `SvGETMAGIC` before a getter that already does it: a tied scalar may return
a different value on each `FETCH`. Document intentional repeated reads.

Get/set magic, stringification overload, callback execution, and a final
decrement can all reenter the module. Keep the current receiver/callback alive,
avoid half-updated native state, and invalidate stale buffer or container-slot
pointers. A refcount increment preserves object lifetime, not value immutability.

For private extension magic, use a unique `MGVTBL` identity, supported attachment
APIs, and explicit payload free/duplication rules. Check `mg_findext` preconditions
before calling it on an arbitrary SV. Do not reuse internal magic implementations
or remove another extension's magic of the same type.

Sources: `perlguts` sections on Reference Counts and Mortality, Working with AVs/
HVs, Magic Variables, and Localizing changes; `perlapi` entries for every API
named above; `perlxs` Returning Values from an XSUB.
