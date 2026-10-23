# Documentation review for the deployed-Perl package

Reviewed on 2026-10-16. This is a routing and maintenance record, not a request
to load all these manuals for every task. The skills distill decisions and
failure mechanisms; the original manuals remain the API references.

## Sources and version boundaries

Installed Perl 5.38.2 documentation was consulted using `perldoc` and installed
POD, including generated `perlapi`. Installed tool versions were MakeMaker
7.70, Module::Build 0.4234, ExtUtils::ParseXS 3.51, Test::More/Test2::V0
1.302222, Test::Harness 3.44, and Devel::PPPort 3.71.

The sibling Perl tree supplied newer explanatory POD, including the expanded
XS manual and tutorials. Its HEAD at review was
`9452ff1ca0af9cf790b502e8c732b01ba6f4626c`; that checkout can contain local
or branch-specific material. It was used as a documentation source, not as an
implicit definition of the installed Perl's supported APIs. In particular,
new parser features, interpreter layouts, and experimental facilities are not
assumed available to deployed extensions.

Upstream documentation was also checked for
[perlxs](https://perldoc.perl.org/perlxs),
[MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker),
[Module::Build](https://metacpan.org/pod/Module::Build),
[Test::More](https://metacpan.org/pod/Test::More),
[Test2::V0](https://metacpan.org/pod/Test2::V0), and
[Test2::V1](https://metacpan.org/pod/Test2::V1).
Online “latest” documentation must be selected for the actual supported version
when resolving availability. The package deliberately does not mandate the
newest framework edition or toolchain for existing projects.

## Primary XS and C API analysis

| Manual/tool | Material examined and resulting guidance |
| --- | --- |
| `perlxs` | XSUB structure, CODE/OUTPUT/PPCODE, return values, implicit mortalization, typemap ordering, output parameters, CLEANUP, opaque handles, C++, MY_CXT, visibility. Inspect generated wrappers and account for normal versus exceptional return paths. |
| `perlxstut` | Build/load pipeline, testing examples, argument stack, typemaps, output-argument warnings, native libraries, PerlIO. Keep the examples' mechanics but use project/version-specific tooling. |
| `perlxstypemap` | INPUT/OUTPUT interpolation, local overrides, T_SV, reference mappings and fixed-refcount variants, pointer objects, opaque data, filehandles. Conversion and ownership are separate decisions. |
| `perlapi` | Public-API boundary and targeted entries for constructors, RVs, mortality, AV/HV store/fetch, SvPV variants, setters, magic, context and callback APIs. Check ownership, magic, length, flags, and availability per entry. |
| `perlguts` | SV conversion, read-only/COW buffers, containers, references, mortality, magic, localization, stacks, concurrency and Unicode. Use ownership ledgers and reentry analysis; exclude internal implementation mechanisms from default extension recipes. |
| `perlcall` | Call flags, scalar/list/void results, SP synchronization, temporary scopes, G_EVAL/G_KEEPERR, stored callbacks. Preserve result/error lifetimes and balance the stack on failure too. |
| `perlembed`, `ExtUtils::Embed` | Build flags, lifecycle, persistent/multiple interpreters, extension loading. Keep host-owned lifecycle guidance conditional on embedding. |
| `perlclib` | Allocator families, memory/string helpers, character handling, locale, libc and process-global concurrency issues. Do not confuse per-interpreter storage with native thread safety. |
| `perlapio`, `perliol` | Opaque PerlIO interfaces, stdio conversion and buffering/layers. Do not cast stream types or bypass a caller's layers accidentally. Layer implementation details are conditional. |
| `ExtUtils::ParseXS`, `xsubpp` | Parser options, version checking, typemap inputs, line directives, generation API. Use the actual configured parser and generated C. |
| `XSLoader` | Package/version matching, bootstrap side effects, BOOT ordering, build-tree loading. Fix mismatches rather than disabling checks. |
| `h2xs`, `ExtUtils::Constant`, `ExtUtils::Constant::XS` | Skeletons and generated constant includes. Maintain generator inputs; the documented Constant interface is preferable to its sparsely documented XS backend. |
| `ExtUtils::XSSymSet` | Checked implementation; no public POD found. Symbol shortening is specialized toolchain behavior, not a general module-development dependency. |
| `Devel::PPPort`, `ExtUtils::CBuilder` | API backports/scanning, shipped compatibility headers, configured compiler/linker probes. Separate API availability from semantic and ABI compatibility. |

## Manuals with guts or tut in their names

The Perl documentation inventory was checked for these names. Relevant sections
were examined according to the scope below; this is not a claim that every
line of every tutorial or third-party implementation was audited.

| Document | Disposition |
| --- | --- |
| `perlguts` | Detailed source for shared XS concepts, as above. |
| `perlreguts` | Checked overview and scope: explicitly an implementation description, not an API definition. Use `perlre`/`perlretut` for module regex behavior and `perlreapi` only for actual engine plugins. |
| `perlclassguts` | Checked storage/API overview: implementation of class syntax. Do not copy private field layouts into extension guidance. Use target public class/object facilities. |
| `perldebguts` | Checked debugger-hook overview and distinction from ordinary debugging. Keep hooks out of default debugging workflow. |
| `perlxstut` | Detailed XS/build/testing source, as above. |
| `perlreftut` | References, shared structures and autovivification. Preserve identity and avoid unintended mutation. |
| `perlootut` | Encapsulation, composition, object-system choices. Preserve existing module design; do not assume blessed hashes. |
| `perlunitut` | Characters versus octets and encode/decode boundaries. Distinguish source UTF-8, decoded text, and encoded bytes. |
| `perlopentut` | Explicit text/binary modes, layers, handles and pipe arguments. Preserve ownership and external boundaries. |
| `perlpacktut` | Numeric widths, endianness, padding/alignment and pointers. Native layouts are not portable wire formats. |
| `perlretut` | Pattern construction, character classes, Unicode and captures. Test semantics at the language level. |
| `perlthrtut` | Cloned interpreter model, module safety and process-scope changes. Test cloning rather than merely using a threaded binary. |
| `perldebtut` | Debugger entry and stepping. Distinguish Perl-flow debugging from native C debugging. |
| `perlhacktut` | Checked scope: interpreter patch tutorial. Its core build, test, and release workflow is excluded. |
| `perldispatchontut` in the sibling checkout | Checked scope: experimental branch-specific language tutorial. Excluded from ordinary deployed-Perl instructions. |
| `Locale::Maketext::Guts`, `GutsLoader` | Checked POD: deprecated compatibility loaders, not general interpreter guidance. No new dependency or workflow. |
| `ExtUtils::MakeMaker::Tutorial` | Distribution layout, manifest, build stages and test discovery. Supplemented with the MakeMaker attribute reference. |
| `Test::Tutorial` | Behavioral assertions, naming, skip and TODO. Supplemented with actual framework and runner APIs. |

XS-named application modules and test fixtures found during inventory (for
example List::Util::XS, JSON backends, and ParseXS fixtures) are consumers or
tests of XS, not additional general XS authoring manuals. They do not establish
a dependency for this package. Third-party application-specific tutorials are
outside this package's general Perl/XS scope.

## Build and test tools

| Documentation | Analysis applied |
| --- | --- |
| MakeMaker main POD and Tutorial | Prerequisite phases and attribute versions; LIBS alternatives; native inputs, test discovery, distribution targets; META versus MYMETA; generated build state. |
| Module::Build main POD, Authoring, API, Cookbook | Actions, prerequisite phases, test_requires availability, CBuilder requirement, xs_files/c_source/flags, custom builders, focused tests and distribution testing. Keep Tiny distinct. |
| Test::More and Test::Tutorial | Comparison semantics, planning, subtests, skips/TODO, diagnostics, premature termination. |
| Test::Simple and Test::Deep | Checked basic TAP assertions/planning and structural/partial comparison examples. Preserve framework choice and distinguish exact results from deliberate matchers. |
| Test2::V0/V1 and Manual testing/planning/migration | Edition-specific imports, deep versus string comparison, reference identity, changed helper signatures, plugins and direct module prerequisites. |
| Test2 Manual tooling/first-tool/testing and Test::Builder::Tester | Caller attribution, context release, event interception and testing expected failures. Conditional on actually writing test helpers. |
| Test::Harness, TAP::Harness, `prove` | TAP plus exit status, staged paths, selected interpreter, discovery, parallel isolation and runner configuration. |
| [Test::Fatal](https://metacpan.org/pod/Test::Fatal), [Test::Warnings](https://metacpan.org/pod/Test::Warnings) | Checked upstream because local POD was absent. Exception capture is not an assertion; warning helpers can add a completion assertion. Optional helpers, not universal prerequisites. |

`perlmod`, `perlnewmod`, `perlmodstyle`, `perlport`, `perlunicode`, and related
manual sections supplied module/API, documentation, and compatibility context.
Historical scaffolding and release suggestions were not turned into mandatory
version bumps, framework migrations, public uploads, or core development tasks.
