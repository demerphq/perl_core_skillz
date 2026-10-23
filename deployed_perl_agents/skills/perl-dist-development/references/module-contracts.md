# Module contracts

## Find the maintained interface

Read the public POD and existing callers before changing argument handling or
return values. Check exports and export tags, prototypes/signatures, method
invocation, subclass behavior, and load-time work. Add to existing mechanisms
rather than selecting a new object system or exporting names by default.

Document arguments, return values in each supported context, encoding, mutation,
exceptions, and resource ownership. For a native wrapper, describe the Perl
contract rather than requiring users to understand the C implementation.

## Semantics that affect compatibility

- `defined`, truth, and existence ask different questions. Do not replace a
  definedness check with `||` when `0`, `"0"`, or an empty string is valid.
- List assignment, scalar assignment, and `return` can impose different
  contexts on callees. Test list, scalar, and void context when the API responds
  differently. Avoid flattening reference-valued results accidentally.
- Arguments in `@_` can alias caller variables. Assign to local variables when
  the interface promises no mutation; copying a reference does not copy its
  referent. Decide whether returned structures share identity or are snapshots.
- A read through a nested reference can autovivify data. Test that inspection
  routines leave inputs unchanged when that is their contract.
- Tied values and overloaded objects run code during ordinary-looking reads,
  comparisons, boolean checks, and stringification. Preserve evaluation counts
  where observable; do not assume all objects are blessed hashes.
- Reference cycles can retain objects indefinitely. Decide which relationships
  own their targets, especially closures retaining callbacks or parent/child
  wrappers. Use weak references only where non-ownership matches the API.
- `local` restores dynamic state on unwind; assignment followed by manual
  restoration does not when an intervening call dies. Localize package variables
  and special variables deliberately. Do not mutate application-wide settings
  to make a module's implementation convenient.

For language behavior consult `perlsub`, `perlref`/`perlreftut`, `perldata`,
`perlobj`/`perlootut`, `overload`, and `perltie`. For reference identity and
weakening use the supported `Scalar::Util` interfaces, not stringified addresses.

## Text, binary data, and external effects

Choose whether the interface consumes characters, encoded octets, or either
under a documented conversion. `use utf8` controls source parsing; it does not
decode external input. Decode/encode at a defined boundary and avoid double
encoding. Test equivalent character strings with upgraded and downgraded
internal representations where both exist.

For files, use lexical handles and explicit open modes/layers according to the
contract. Do not alter a caller-owned handle's layers or close it unexpectedly.
Preserve list-form process invocation when arguments are data. Use `perlunitut`,
`perlopentut`, `perlunicode`, and `Encode` for details.

For binary formats, specify widths, endianness, signedness, and truncation
policy. `perlpacktut` explains why native layouts, padding, and packed pointers
are unsuitable as a portable interchange format. Test short and malformed
input, not just values produced by the matching encoder.

For regex changes, use `perlre` and `perlretut`: check anchoring, interpolation
and quoting, character classes, Unicode/locale modifiers, capture shape, and
failure behavior. Regex implementation layouts are not a module API.

## Errors and documentation

Keep errors useful to the caller and compatible with the project's policy.
Use `Carp` where a caller-facing diagnostic is appropriate. Preserve exception
objects rather than converting every error to a string. Do not catch an error
and turn it into an ordinary empty result unless that is the documented API.

POD examples should use declared dependencies and supported syntax. Validate
changed POD with `podchecker` or the project's POD tests, and test substantive
examples. Follow the existing changelog/versioning practice. `perlnewmod` and
`perlmodstyle` are background guidance, not authority to replace project policy
with every historical tutorial recommendation.
