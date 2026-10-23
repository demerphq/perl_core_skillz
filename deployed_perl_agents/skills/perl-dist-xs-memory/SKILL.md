---
name: perl-dist-xs-memory
description: "Analyze or fix XS value lifetimes, SV/AV/HV ownership, reference counts, mortalization, magic, tied values, copy-on-write, and byte/Unicode string boundaries in Perl extensions."
---

# XS values, ownership, and strings

For every retained value, identify who owns the reference and which operation
ends that ownership. Count ownership obligations, not just refcount increments
and decrements. `sv_2mortal` transfers an owned reference to temporary cleanup;
it does not create an extra reference or make a borrowed pointer safe forever.

1. Trace creation, borrowing, retention, transfer, and release through both
   handwritten C and the generated XSUB. Include return conversion, container
   stores, error exits, and destruction.
2. Treat coercion, magic, overload, callbacks, and final decrements as possible
   entries into user code. Keep objects alive and state consistent across
   reentry. A retained SV does not guarantee a previously fetched PV address
   remains valid.
3. Establish whether reads and writes must invoke get/set magic. Do not add
   duplicate `FETCH` calls or bypass `STORE` by choosing the wrong API variant.
4. Specify the string contract before selecting `SvPVbyte`, `SvPVutf8`, or
   `SvPV` plus encoding information. Carry explicit byte lengths and handle
   embedded NULs, buffer lifetimes, and output flags deliberately.
5. Test the affected lifetime or representation boundary, including repeated
   calls and error paths where relevant. Show why each ownership transfer is
   balanced; adding an increment until a crash disappears is not a proof.

Read [ownership-magic.md](references/ownership-magic.md) for reference ledgers,
containers, hash iteration, shared hash keys, exception cleanup, and retention
across callbacks. Read
[strings.md](references/strings.md) for string conversion and mutation.

Check exact contracts in the target Perl's `perlapi`, particularly ownership,
magic processing, return lifetime, and API availability. `perlguts` explains
mechanisms; internal examples there do not by themselves make an API public.
