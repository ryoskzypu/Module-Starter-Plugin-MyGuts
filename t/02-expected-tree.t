#!/usr/bin/env perl
#
# This test compares files produced by Module::Starter::Plugin::MyGuts against
# an expected snapshot of the distro tree; they must have the same contents.

use v5.40.0;

use strict;
use warnings;

use Test2::V1             qw< note pass fail >;
use Test2::Plugin::UTF8   qw< encoding_only >;
use File::Spec::Functions qw< catfile curdir updir >;
use File::Basename        qw< basename >;
use File::Temp            qw< tempdir >;
use Text::Diff;

use Module::Starter::Plugin::MyGuts;

# Emulate GNU diff --recursive -u
#
# References:
#   https://en.wikipedia.org/wiki/Diff
#   https://softwareengineering.stackexchange.com/questions/358786/what-are-golden-files
#
# NOTE:
#   Based on File::DirCompare and does not follow symlinks, for the sake of simplicity
#   and avoid infinite loops.
sub diff_recurse ( $dir_a, $dir_b )
{
    my %top_entries;

    foreach my $dir ( $dir_a, $dir_b ) {
        -d $dir or die "$dir does not exist: $!";

        # Glob hidden + normal filenames.
        my $all = catfile( $dir, '.* ' ) . catfile( $dir, '*' );
        $top_entries{ basename $_ } = 1 foreach ( glob $all );
    }

    # Prune dot ('.', '..') entries.
    delete $top_entries{ curdir() } if $top_entries{ curdir() };
    delete $top_entries{ updir() }  if $top_entries{ updir() };

    foreach my $name ( sort keys %top_entries ) {
        my $name_a = catfile( $dir_a, $name );
        my $name_b = catfile( $dir_b, $name );

        # Dir/file exists only in dir_a or dir_b.
        if ( -e $name_a && !-e $name_b ) {
            note("Only in $dir_a: $name");
            fail("$name is missing in $dir_b");
        }
        elsif ( -e $name_b && !-e $name_a ) {
            note("Only in $dir_b: $name");
            fail("Extraneous $name in $dir_b");
        }

        # Both are existing dirs, recurse.
        if ( -d $name_a && -d $name_b ) {
            diff_recurse( $name_a, $name_b );
        }
        # Both are existing files, diff.
        elsif ( -f $name_a && -f $name_b ) {
            # NOTE:
            #   COLOR is a feature from a fork of Text::Diff that isn't merged to
            #   upstream yet, so to get colorized diff output it needs to replaced.
            #   E.g.
            #     cpanm --reinstall https://github.com/ryoskzypu/Text-Diff.git@colors
            if ( my $diff = diff( $name_a, $name_b, { COLOR => 'always' } ) ) {
                fail("Files $name_a and $name_b are different");
                note($diff);
            }
            else {
                pass("Files $name_a and $name_b are equal");
            }
        }
    }
}

# Initialize a temporary directory and Module::Starter distro options.

my $temp_dir = tempdir( CLEANUP => 1 );

my $distro         = 'Foo-Bar';
my $build_dir_orig = catfile( 't/data',   $distro );
my $build_dir_new  = catfile( $temp_dir, $distro );

my $module = $distro =~ s{-}{::}gr;

my %config = (
    dir          => $build_dir_new,
    modules      => [$module],
    builder      => [ qw< ExtUtils::MakeMaker > ],
    license      => 'MIT_0',
    genlicense   => 1,
    ignores_type => [ qw< git manifest > ],
    author       => ['author <author@email>'],
    github       => 'author',
    minperl      => 'v5.40.0',
    verbose      => 1,

);

# Create the distribution and begin test.

my $guts = Module::Starter::Plugin::MyGuts->new(%config);
$guts->create_distro;
$guts->post_create_distro;

diff_recurse( $build_dir_orig, $build_dir_new );

T2->done_testing;
