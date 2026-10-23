use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use File::Find qw(find);
use File::Spec;

my $root = abs_path(File::Spec->catdir(dirname(__FILE__), '..'));
my $skills = File::Spec->catdir($root, 'skills');
my @entries = sort glob File::Spec->catfile($skills, '*', 'SKILL.md');
ok(@entries, 'package contains discoverable skills');
my %names;

for my $entry (@entries) {
    my $dir = dirname($entry);
    my $folder = basename($dir);
    subtest $folder => sub {
        my $body = read_file($entry);
        my ($frontmatter) = $body =~ /\A---\n(.*?)\n---\n/s;
        ok(defined $frontmatter, 'frontmatter exists') or return;
        my ($name) = $frontmatter =~ /^name: ([a-z0-9-]+)$/m;
        is($name, $folder, 'discovery name matches installation directory');
        ok(!$names{$name}++, 'skill name is unique') if defined $name;
        like($frontmatter, qr/^description: \S.+$/m, 'discovery description exists');

        my @files;
        find({ no_chdir => 1, wanted => sub {
            push @files, $File::Find::name if -f $_ && /\.md\z/;
        } }, $dir);
        my %reachable = ($entry => 1);
        my %links;
        for my $file (@files) {
            my $text = read_file($file);
            while ($text =~ /\[[^\]\n]+\]\(([^)\s]+)\)/g) {
                my $target = $1;
                next if $target =~ m{\Ahttps?://};
                $target =~ s/#.*//;
                next unless length $target;
                my $path = abs_path(File::Spec->catfile(dirname($file), $target));
                ok(defined($path) && -f $path, "reference resolves: $target");
                next unless defined $path;
                my $relative = File::Spec->abs2rel($path, $dir);
                unlike($relative, qr{\A\.\.(?:[/\\]|\z)},
                    "reference remains inside independently installable skill: $target");
                push @{$links{$file}}, $path;
            }
        }
        my @todo = ($entry);
        while (@todo) {
            my $file = shift @todo;
            for my $target (@{$links{$file} || []}) {
                push @todo, $target unless $reachable{$target}++;
            }
        }
        ok($reachable{$_}, 'resource is reachable: ' . File::Spec->abs2rel($_, $dir))
            for @files;
        done_testing;
    };
}

done_testing;

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
