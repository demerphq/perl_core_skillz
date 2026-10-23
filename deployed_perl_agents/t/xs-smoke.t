use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Handle;
use Text::ParseWords qw(shellwords);

my $root = abs_path(File::Spec->catdir(dirname(__FILE__), '..'));
my $scratch = tempdir(CLEANUP => 1);
my $origin = getcwd();
my $has_builder = eval { require Module::Build; 1 };
my $has_test2 = eval { require Test2::V0; 1 };
require ExtUtils::CBuilder;
my $compiler = ExtUtils::CBuilder->new(quiet => 1);
chdir $scratch or die "chdir $scratch: $!";
my $has_compiler = $compiler->have_compiler;
chdir $origin or die "chdir $origin: $!";
plan skip_all => 'a working C compiler and linker are needed for XS examples'
    unless $has_compiler;

# Compile the actual examples, so edits to the guidance cannot leave a stale
# independently maintained copy passing this smoke test.
my $interfaces = read_file(File::Spec->catfile($root, 'skills', 'perl-dist-xs',
    'references', 'interfaces.md'));
my @examples = $interfaces =~ /^```xs\n(.*?)^```/msg;
is(scalar @examples, 2, 'found scalar and array-reference examples');
my $context_doc = read_file(File::Spec->catfile($root, 'skills',
    'perl-dist-portability', 'references', 'interpreter-state.md'));
my ($preamble) = $context_doc =~ /^```c\n(.*?)^```/ms;
ok(defined $preamble, 'found explicit interpreter context example');
BAIL_OUT('documented XS examples are missing') unless @examples == 2 && $preamble;

my $xs = $preamble . <<'XS' . join("\n", @examples);

MODULE = Skill::Probe  PACKAGE = Skill::Probe

PROTOTYPES: DISABLE

SV *
context_answer()
    CODE:
        RETVAL = make_answer(aTHX_ 42);
    OUTPUT:
        RETVAL

SV *
borrowed(value)
    SV *value
    CODE:
        RETVAL = SvREFCNT_inc(value);
    OUTPUT:
        RETVAL

SV *
copy_bytes(value)
    SV *value
    PREINIT:
        STRLEN len;
        const char *buffer;
    CODE:
        buffer = SvPVbyte(value, len);
        RETVAL = newSVpvn(buffer, len);
    OUTPUT:
        RETVAL

UV
utf8_size(value)
    SV *value
    PREINIT:
        STRLEN len;
        const char *buffer;
    CODE:
        buffer = SvPVutf8(value, len);
        PERL_UNUSED_VAR(buffer);
        RETVAL = (UV)len;
    OUTPUT:
        RETVAL

XS

my $module = <<'PM';
package Skill::Probe;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);
1;
PM

my $tests = <<'TEST';
use strict;
use warnings;
use Skill::Probe;
use Scalar::Util qw(weaken);

is(Skill::Probe::answer(), 42, 'fresh scalar return');
is(Skill::Probe::context_answer(), 42, 'explicit helper context');
my $array = Skill::Probe::empty_array();
is(ref($array), 'ARRAY', 'newRV_noinc returns an array reference');
is(scalar @$array, 0, 'array starts empty');
push @$array, 17;
is($array->[0], 17, 'container remains usable after XSUB return');
my $observer = $array;
weaken($observer);
undef $array;
ok(!defined($observer), 'container is released when last owner leaves');

my $source = 'alive';
for (1 .. 200) {
    my $result = Skill::Probe::borrowed($source);
    is($result, 'alive', 'borrowed SV survives generated mortalization') if $_ == 200;
}
is($source, 'alive', 'caller retains its original owner');

my $bytes = "a\0\xff";
is(Skill::Probe::copy_bytes($bytes), $bytes, 'explicit length preserves NUL and high byte');
my $upgraded = $bytes;
utf8::upgrade($upgraded);
is(Skill::Probe::copy_bytes($upgraded), $bytes, 'equivalent upgraded bytes convert consistently');
is(Skill::Probe::copy_bytes(''), '', 'empty string');
my $wide = chr(0x100);
my $succeeded = eval { Skill::Probe::copy_bytes($wide); 1 };
my $error = $@;
ok(!$succeeded, 'byte conversion rejects unrepresentable characters');
like($error, qr/Wide character/, 'rejection comes from byte conversion');
my $encoded = chr(0xff);
utf8::encode($encoded);
is(Skill::Probe::utf8_size(chr(0xff)), length($encoded), 'UTF-8 conversion measures bytes');

{
    package Skill::FetchCounter;
    sub TIESCALAR { bless { count => 0 }, shift }
    sub FETCH { ++$_[0]->{count}; return "x\0y" }
}
tie my $tied, 'Skill::FetchCounter';
my $counter = tied($tied);
is(Skill::Probe::copy_bytes($tied), "x\0y", 'getter reads magical value');
is($counter->{count}, 1, 'conversion invokes one intended FETCH');
done_testing;
TEST

for my $driver (qw(makemaker module-build)) {
    subtest $driver => sub {
        plan skip_all => 'Module::Build is not installed'
            if $driver eq 'module-build' && !$has_builder;
        my $dir = File::Spec->catdir($scratch, $driver);
        make_path(File::Spec->catdir($dir, 'lib', 'Skill'),
                  File::Spec->catdir($dir, 't'));
        write_file(File::Spec->catfile($dir, 'lib', 'Skill', 'Probe.pm'), $module);
        write_file(File::Spec->catfile($dir, 't', 'more.t'), "use Test::More;\n" . $tests);
        write_file(File::Spec->catfile($dir, 't', 'test2.t'),
            "use Test2::V0 -no_srand => 1;\n" . $tests) if $has_test2;
        my @files = ('lib/Skill/Probe.pm', 't/more.t', 'MANIFEST');
        push @files, 't/test2.t' if $has_test2;
        if ($driver eq 'makemaker') {
            write_file(File::Spec->catfile($dir, 'Probe.xs'), $xs);
            write_file(File::Spec->catfile($dir, 'Makefile.PL'), <<'PL');
use ExtUtils::MakeMaker;
my %tests = ('Test::More' => '0.88');
$tests{'Test2::V0'} = 0 if -f 't/test2.t';
WriteMakefile(
    NAME => 'Skill::Probe', VERSION_FROM => 'lib/Skill/Probe.pm',
    ABSTRACT => 'Temporary deployed-Perl skill validation',
    AUTHOR => 'Skill validation', LICENSE => 'perl_5',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
    TEST_REQUIRES => \%tests,
);
PL
            push @files, 'Makefile.PL', 'Probe.xs';
        }
        else {
            write_file(File::Spec->catfile($dir, 'lib', 'Skill', 'Probe.xs'), $xs);
            write_file(File::Spec->catfile($dir, 'Build.PL'), <<'PL');
use Module::Build;
my %tests = ('Test::More' => '0.88');
$tests{'Test2::V0'} = 0 if -f 't/test2.t';
Module::Build->new(
    module_name => 'Skill::Probe', license => 'perl',
    dist_abstract => 'Temporary deployed-Perl skill validation',
    dist_author => 'Skill validation',
    configure_requires => { 'Module::Build' => '0.4004' },
    build_requires => { 'ExtUtils::CBuilder' => 0 },
    test_requires => \%tests,
)->create_build_script;
PL
            push @files, 'Build.PL', 'lib/Skill/Probe.xs';
        }
        write_file(File::Spec->catfile($dir, 'MANIFEST'), join("\n", sort @files) . "\n");
        # Keep diagnostics outside the fixture's release contents.
        my $log = File::Spec->catfile($scratch, "$driver.log");
        chdir $dir or die "chdir $dir: $!";
        my @make = shellwords($Config{make});
        my @steps = $driver eq 'makemaker'
            ? ([$^X, 'Makefile.PL'], [@make],
               [@make, 'test', 'TEST_FILES=t/more.t', 'TEST_VERBOSE=1'],
               [@make, 'test'], [@make, 'disttest'])
            : ([$^X, 'Build.PL'], [$^X, 'Build'],
               [$^X, 'Build', 'test', '--test_files', 't/more.t', '--verbose', '1'],
               [$^X, 'Build', 'test'], [$^X, 'Build', 'disttest']);
        for my $step (@steps) {
            my $status = run_logged($log, @$step);
            ok($status == 0, join(' ', @$step));
            if ($status != 0) {
                diag(read_file($log));
                last;
            }
        }
        SKIP: {
            skip 'Test2::V0 is not installed', 1 unless $has_test2;
            ok(-f File::Spec->catfile('t', 'test2.t'), 'Test2 assertions included in full and distribution tests');
        }
        chdir $origin or die "chdir $origin: $!";
        done_testing;
    };
}
done_testing;

sub run_logged {
    my ($log, @command) = @_;
    STDOUT->flush;
    STDERR->flush;
    open my $saved_out, '>&', \*STDOUT or die "save stdout: $!";
    open my $saved_err, '>&', \*STDERR or die "save stderr: $!";
    open STDOUT, '>>', $log or die "open $log: $!";
    open STDERR, '>&', \*STDOUT or die "redirect stderr: $!";
    my $status = system { $command[0] } @command;
    open STDOUT, '>&', $saved_out or die "restore stdout: $!";
    open STDERR, '>&', $saved_err or die "restore stderr: $!";
    return $status;
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
}
