package Module::Starter::Plugin::MyGuts;

use v5.40.0;

use strict;
use warnings;
use utf8;
use version;
use open qw< :std :encoding(UTF-8) >;  # Encode/decode STDIN, STDOUT, STDERR, and filehandles to UTF-8.

use parent qw< Module::Starter::Simple >;

use File::Spec ();
use File::Path qw< make_path >;
use Carp       qw< confess >;

our $VERSION = 'v1.0.0';

# Initial distribution version (dotted)
my $DIST_VERSION = 'v1.0.0';           # Stable API initial release (SemVer)

sub new ( $class, @args )
{
    my $self = $class->SUPER::new(@args);

    if ( defined $self->{builder} ) {
        die 'Only ExtUtils::MakeMaker is supported' if $self->{builder}[0] ne 'ExtUtils::MakeMaker';
        die 'Only one builder is supported'         if scalar $self->{builder}->@* > 1;
    }

    return $self;
}

sub post_create_distro ($self)
{
    if ( defined $self->{github} ) {
        # Create GitHub workflows directory and its CI file.
        my $workflows = File::Spec->catdir( $self->{basedir}, '.github', 'workflows' );
        if ( make_path $workflows ) {
            $self->progress("Created $workflows");
            $self->create_CI($workflows);
        }
        else {
            warn "Failed to create GitHub workflows directory: $!";
        }

        # Create docs directory.
        #
        # NOTE:
        #   To reflect the 'Support and documentation' section, make sure to convert the
        #   distribution files that contain POD to Markdown (with pod2markdown) and put
        #   them in the docs directory.
        my $docs = File::Spec->catdir( $self->{basedir}, 'docs' );
        if ( mkdir $docs ) {
            $self->progress("Created $docs");

            # Create a stub file so docs is shown on GitHub.
            my @parts    = split /::/, $self->{main_module};
            my $filepart = ( pop @parts ) . '.md';
            my $fname    = File::Spec->catdir( $docs, $filepart );

            $self->create_file( $fname, '' );
            $self->progress("Created $fname");
        }
        else {
            warn "Failed to create docs directory: $!";
        }

        $self->create_README_md;
    }
}

# See:
#   https://docs.github.com/en/actions/get-started/understand-github-actions
#   https://perlmaven.com/what-is-ci
#   https://perlhacks.com/2024/01/github-actions-for-perl-development/
#   https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
#   https://github.com/perl-actions/install-with-cpanm
#   https://github.com/FGasper/perl-github-action-tips
#   https://metacpan.org/pod/Devel::Cover::Report::Coveralls
#   https://github.com/ryoskzypu/github_workflows
sub create_CI ( $self, $fpath )
{
    my $fname    = File::Spec->catfile( $fpath, 'ci.yml' );
    my $workflow = q{ryoskzypu/github_workflows/.github/workflows/perl-test.yml@main};

    my $ci = <<~"END";
    name: 'CI'
    description: 'Call perl-test.yml on every push and pull request'

    on:
      push:
        branches:
          - '*'
        tags-ignore:
          - '*'
      pull_request:
      workflow_dispatch:

    jobs:
      call-perl-test:
        uses: $workflow
        with:
          since-perl: '$self->{minperl}'
          with-devel: true
          coverage: true
    END

    $self->create_file( $fname, $ci );
    $self->progress("Created $fname");
}

# See:
#   https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes
#   https://www.markdownguide.org/basic-syntax/
#   https://google.github.io/styleguide/docguide/style.html
#   https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
sub create_README_md ($self)
{
    my $fname   = File::Spec->catfile( $self->{basedir}, 'README.md' );
    my $readme  = $self->README_guts('');
    my $license = $self->_get_license( POD => 1 );

    $readme = <<~"END";
        # $self->{main_module}

        $self->{bp}{readme_intro}
        ## Installation

        To download and install this module directly with [cpanminus](https://metacpan.org/pod/App::cpanminus):

        ```shell
        \$ cpanm $self->{res}{repository}.git
        ```

        To do it manually, run the following commands (after cloning the repository):

        ```shell
        \$ cd $self->{distro}
        \$ perl Makefile.PL
        \$ make
        \$ make test
        \$ make install
        ```

        ## Support and documentation

        You can find documentation for this module in [docs](docs/) or with the
        `perldoc` command (after installing):

        ```shell
        \$ perldoc $self->{main_module}
        ```

        You can also look for information at:

        - GitHub issue tracker (report bugs here)

            $self->{res}{bug_tracker}

        - Search CPAN

            https://metacpan.org/dist/$self->{distro}

        ## Copyright

        $license
        END

    $self->create_file( $fname, $readme );
    $self->progress("Created $fname");
}

# See:
#   https://perldoc.perl.org/perlmodstyle
#   https://perldoc.perl.org/perlpodstyle
#   https://pause.perl.org/pause/query?ACTION=pause_namingmodules
#   https://blogs.perl.org/users/neilb/2014/08/the-right-name-for-your-cpan-distribution.html
#   https://blogs.perl.org/users/neilb/2014/07/give-your-modules-a-good-abstract.html
#   https://www.neilb.org/2015/12/20/specify-perl-version.html
#   https://old.reddit.com/r/perl/comments/5i4vn9/version_numbers/
#   https://semver.org/
#   https://blogs.perl.org/users/dean/2022/08/please-relicense-from-perl-5-to-mit-or-apache-20-license.html
#   https://github.com/aws/mit-0
sub module_guts ( $self, $module, $rtname )
{
    # Remove true value at the end if minimum perl is >= v5.38.0.
    my $mod_true = version->parse( $self->{minperl} ) >= version->parse('v5.38.0');

    # NOTE:
    #   module_guts method is the first executed in the *_guts chain, thus some
    #   attributes should be set here. The boilerplate/metadata methods must be
    #   called here in order for them to access the attributes from Module::Starter::Simple::_create_module().
    $self->{author_full} = $self->{author}[0];
    $self->{author_name} = $self->{author_full} =~ s{ <.+\z}{}r;  # Strip email
    $self->_build_boilerplates;
    $self->{res} = $self->_get_resources;

    my $header  = "package $module;\n\n$self->{bp}{header}";
    my $license = $self->_get_license( POD => 1 );

    my $content = $header . <<~"END";
        our \$VERSION = '$DIST_VERSION';

        $self->{bp}{stub_function1}
        $self->{bp}{stub_function2}
        \=encoding UTF-8

        \=head1 NAME

        $module - $self->{bp}{abstract}

        \=head1 SYNOPSIS

        $self->{bp}{synopsis}
        \=head1 DESCRIPTION

        $self->{bp}{description}

        \=head1 EXPORTS

        $self->{bp}{exports}
        \=head1 SUBROUTINES/METHODS

        $self->{bp}{functions}
        \=head1 BUGS

        Report bugs at L<$self->{res}{bug_tracker}>.

        \=head1 AUTHOR

        $self->{author_full}

        \=head1 SEE ALSO

        $self->{bp}{see_also}
        \=head1 COPYRIGHT

        $license

        \=cut

        1;
        END

    $content =~ s{
        ^\n
        1;\n
        \z
    }
    {}mx if $mod_true;

    return $content;
}

# See:
#   https://archive.shadowcat.co.uk/blog/matt-s-trout/mstpan-11/
#   https://old.reddit.com/r/perl/comments/ad7vyq/how_to_write_perl_modules_for_cpan_the_modern_way/
#   https://old.reddit.com/r/perl/comments/13ib46n/distzilla_considered_annoying/
#   https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/cpan-packaging.md
#   https://blogs.perl.org/users/neilb/2017/04/an-introduction-to-distribution-metadata.html
#   https://blogs.perl.org/users/neilb/2017/04/dependency-phases-in-cpan-distribution-metadata.html
#   https://blogs.perl.org/users/neilb/2017/05/specifying-dependencies-for-your-cpan-distribution.html
sub Makefile_PL_guts ( $self, $main_module, $main_pm_file )
{
    my $sl_name =
        $self->{license_record}
      ? $self->{license_record}->meta2_name
      : $self->{license};

    my $meta_merge = $self->Makefile_PL_meta_merge;

    # NOTE:
    #   EUMM 6.64 is the minimum version that supports CONFIGURE_REQUIRES, TEST_REQUIRES,
    #   and META_MERGE attributes.
    my $makefile = $self->{bp}{header} . <<~"END";
        use ExtUtils::MakeMaker;

        my %WriteMakefileArgs = (
            NAME             => '$main_module',
            AUTHOR           => q{$self->{author_full}},
            VERSION_FROM     => '$main_pm_file',
            ABSTRACT_FROM    => '$main_pm_file',
            LICENSE          => '$sl_name',
            MIN_PERL_VERSION => '$self->{minperl}',
            EXE_FILES        => [
                #'bin/prog',
            ],
            CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => '6.64',
            },
            TEST_REQUIRES => {
                'Test2::V1' => '0',
            },
            PREREQ_PM => {
                #'ABC'              => '1.6',
                #'Foo::Bar::Module' => '5.0401',
            },
        $meta_merge);

        WriteMakefile(%WriteMakefileArgs);
        END

    # Do not declare a minimum perl version.
    if ( defined $self->{no_minperl} && $self->{no_minperl} ) {
        # Strip metadata info.
        $makefile =~ s{^\x{20}+MIN_PERL_VERSION => [^,]+,\n}{}m;
    }

    return $makefile;
}

# See:
#   https://metacpan.org/pod/ExtUtils::MakeMaker#META_MERGE
#   https://metacpan.org/pod/CPAN::Meta::Spec#Prereq-Spec
#   https://blogs.perl.org/users/neilb/2017/04/specifying-the-type-of-your-cpan-dependencies.html
#   https://perlmaven.com/how-to-add-link-to-version-control-system-of-a-cpan-distributions
#   https://metacpan.org/pod/CPAN::Meta::Spec#resources.
#   https://metacpan.org/about/metadata
#   https://libera.chat/guides/webchat
#   https://perlmaven.com/how-to-add-list-of-contributors-to-the-cpan-meta-files
sub Makefile_PL_meta_merge ($self)
{
    return <<~"END";
        META_MERGE => {
            'meta-spec' => { version => 2 },
            no_index    => {
                directory => [
                    qw<
                        eg
                        examples
                        share
                        t
                        xt
                    >
                ],
            },
            prereqs => {
                develop => {
                    recommends => {
                        'App::CPANTS::Lint' => '0',
                        'Data::Printer'     => '0',
                        'Devel::Cover'      => '0',
                        'Perl::Critic'      => '0',
                        'Perl::Tidy'        => '0',
                    },
                    requires => {
                        'Test::CPAN::Changes' => '0',
                        'Test::Kwalitee'      => '0',
                        'Test::Perl::Critic'  => '0',
                        'Test::Pod'           => '0',
                        'Test::Pod::Coverage' => '0',
                        'Test::Spelling'      => '0',
                    },
                },
                #runtime => {
                #    recommends => {
                #        'Foo::Bar' => '0',
                #    },
                #    suggests => {
                #        'Foo::Bat' => '0',
                #    },
                #},
                #test => {
                #    recommends => {
                #        'Foo::Bar' => '0',
                #    },
                #    suggests => {
                #        'Foo::Bat' => '0',
                #    },
                #},
            },
            resources => {
                repository => {
                    type => 'git',
                    url  => '$self->{res}{repository}.git',
                    web  => '$self->{res}{repository}',
                },
                bugtracker => {
                    web => '$self->{res}{bug_tracker}',
                },
                #homepage => '$self->{res}{homepage}',
                #'x_IRC' => {
                #    url => 'irc://irc.libera.chat/#channel',
                #    web => 'https://web.libera.chat/?nick=Guest?#channel',
                #}
            },
            x_contributors => [
                q{$self->{author_full}},
            ],
        },
    END
}

# See:
#   https://neilb.org/2015/10/18/spotters-guide.html#text:~:text=Changes,-The
#   https://metacpan.org/dist/CPAN-Changes/view/lib/CPAN/Changes/Spec.pod
#   https://blogs.perl.org/users/grinnz/2018/04/a-guide-to-versions-in-perl.html
sub Changes_guts ($self)
{
    chomp( my $changelog = $self->{bp}{changelog} );

    return <<~"END";
        Revision history for $self->{main_module}

        $changelog
        END
}

# See:
#   https://neilb.org/2015/10/18/spotters-guide.html#text:~:text=README
sub README_guts ( $self, $build_instructions )
{
    my $bugs_header =
      defined $self->{github}
      ? 'GitHub issue tracker (report bugs here)'
      : q{CPAN's request tracker (report bugs here)};

    my $readme = <<~"END";
        $self->{main_module}

        $self->{bp}{readme_intro}

        INSTALLATION

        To download and install this module, use your favorite CPAN client:

            cpanm $self->{main_module}

        To do it manually, run the following commands (after downloading and unpacking
        the tarball):

            perl Makefile.PL
            make
            make test
            make install


        SUPPORT AND DOCUMENTATION

        After installing, you can find documentation for this module with the perldoc
        command:

            perldoc $self->{main_module}

        You can also look for information at:

            $bugs_header
                $self->{res}{bug_tracker}

            Search CPAN
                https://metacpan.org/dist/$self->{distro}


        COPYRIGHT

        $self->{bp}{license}
        END

    return $readme;
}

# See:
#   https://neilb.org/2015/10/18/spotters-guide.html#text:~:text=t,-%2F
#   https://metacpan.org/pod/Test2::Manual::Testing::Introduction
#   https://metacpan.org/pod/Test2::V1
sub t_guts ( $self, @modules )
{
    my %t_files;
    my $use_mod;
    my $shebang = '#!/usr/bin/env perl';
    my $header  = "$shebang\n\n$self->{bp}{header}";

    foreach my $mod (@modules) {
        $use_mod .= "use ok '$mod';\n";
    }
    chomp $use_mod;

    $t_files{'00-load.t'} = $header . <<~"END";
        use Test2::V1;

        $use_mod

        foreach my \$mod ( qw< @modules > ) {
            my \$mod_ver = '\$' . \$mod . '::VERSION';

            T2->diag(
                sprintf "Testing \$mod %s, Perl %s, %s",
                \$mod_ver, \$], \$^X,
            );
        }

        T2->done_testing;
        END

    return %t_files;
}

# See:
#   https://neilb.org/2015/10/18/spotters-guide.html#text:~:text=xt
sub xt_guts ( $self, @modules )
{
    my %xt_files;
    my $shebang = '#!/usr/bin/env perl';
    my $header  = "$shebang\n\n$self->{bp}{header}";

    # perlcritic
    # https://metacpan.org/pod/Test::Perl::Critic
    {
        $xt_files{'critic.t'} = $header . <<~'END';
        use Test2::Require::Module qw< Test::Perl::Critic >;
        use Test::Perl::Critic;

        my $EXE = 'bin';

        my @FILES = (
            qw<
                Makefile.PL
                lib
                t
                xt
            >
        );

        push @FILES, $EXE if -e $EXE && -d $EXE;

        all_critic_ok(@FILES);
        END
    }

    # Manifest tests
    # https://metacpan.org/pod/ExtUtils::Manifest
    {
        $xt_files{'manifest.t'} = $header . <<~'END';
            use Test2::V1 qw< is >;
            T2->plan(2);

            use ExtUtils::Manifest qw< manicheck filecheck >;

            is(
                [ manicheck() ], [],
                'manicheck() - missing files',
            );

            is(
                [ filecheck() ], [],
                'filecheck() - extra files',
            );
            END
    }

    # Changes tests
    # https://metacpan.org/pod/Test::CPAN::Changes
    {
        $xt_files{'cpan-changes.t'} = $header . <<~'END';
            use Test2::Require::Module qw< Test::CPAN::Changes >;
            use Test::CPAN::Changes;

            changes_ok();
            END
    }

    # POD tests
    #
    # https://metacpan.org/pod/Test::Pod
    # https://metacpan.org/pod/Test::Pod::Coverage
    # https://metacpan.org/pod/Test::Spelling
    {
        $xt_files{'pod-syntax.t'} = $header . <<~'END';
            use Test2::Require::Module qw< Test::Pod >;
            use Test::Pod;

            my $EXE = 'bin';

            my @DIRS = (
                qw<
                    lib
                >
            );

            push @DIRS, $EXE if -e $EXE && -d $EXE;

            all_pod_files_ok( all_pod_files(@DIRS) );
            END

        $xt_files{'pod-coverage.t'} = $header . <<~'END';
            use Test2::Require::Module qw< Test::Pod::Coverage >;
            use Test::Pod::Coverage;

            all_pod_coverage_ok();
            END

        $xt_files{'pod-spell.t'} = $header . <<~"_";
            use Test2::V1              qw< diag >;
            use Test2::Require::Module qw< Test::Spelling >;

            use Test::Spelling;
            use Pod::Wordlist;

            diag <<'END';
            NOTE:
              This test requires a spellchecker with an English dictionary installed, e.g. aspell.

            END

            add_stopwords(<DATA>);

            all_pod_files_spelling_ok(
                qw<
                    bin
                    script
                    lib
                >
            );

            __DATA__
            $self->{author_name}
            _
    }

    # Kwalitee tests
    #
    # https://metacpan.org/pod/App::CPANTS::Lint
    # https://metacpan.org/pod/Test::Kwalitee
    {
        $xt_files{'kwalitee.t'} = $header . <<~"_";
            use Test2::V1              qw< diag >;
            use Test2::Require::Module qw< Test::Kwalitee >;

            use Test::Kwalitee qw< kwalitee_ok >;

            diag <<'END';
            NOTE:
              This test must be done in the unpacked release tarball directory, which
              misses some kwalitee indicators.

              For a more complete test, install App::CPANTS::Lint and run it on the
              release tarball:

                \$ cpanm App::CPANTS::Lint
                \$ cpants_lint.pl --color --verbose $self->{distro}-$DIST_VERSION.tar.gz

            END

            kwalitee_ok();
            T2->done_testing;
            _
    }

    # Boilerplate tests
    {
        my $module_bp_tests;

        foreach my $mod (@modules) {
            my $file = $self->_module_to_pm_file($mod);
            $module_bp_tests .= "not_in_file_ok('$file');\n";
        }
        chomp $module_bp_tests;

        $xt_files{'boilerplate.t'} = "$shebang\n" . <<~'END';
            #
            # Test to ensure that no boilerplate text generated by Module::Starter::Plugin::MyGuts
            # is left in the distribution files.
            #
            # NOTE:
            #   To see verbose output in correct order, use yath or run:
            #     prove -l xt/boilerplate.t --merge -v

            END

        $xt_files{'boilerplate.t'} .= $self->{bp}{header} . <<~'END';
            use Test2::V1 qw<
                note
                diag
                pass
                fail
            >;

            use re qw< eval >;
            #use DDP output => 'stdout';

            sub not_in_file_ok
            {
                my $filename = shift;

                note("FILENAME: $filename\n\n");

                open my $fh, '<', $filename or die "Failed to open $filename for reading: $!";
                my $file = do { local $/ = undef; <$fh> };  # Slurp entire file.
                close $fh or die $!;

                my $desc;
                my @regex_type;

            END

        # Inject the boilerplates texts for their regex compilations.
        $xt_files{'boilerplate.t'} .= <<~"END";
                my \@readme_rgx = (
                    '\Q$self->{bp}{readme_intro}\E(?{ \$desc = "introduction" })',
                );

                my \@changes_rgx = (
                    '\Q$self->{bp}{changelog}\E(?{ \$desc = "changelog" })',
                );

                my \@modules_rgx = (
                    '\Q$self->{bp}{stub_function1}\E(?{ \$desc = "stub function1 definition" })',
                    '\Q$self->{bp}{stub_function2}\E(?{ \$desc = "stub function2 definition" })',
                    '[^ \\n]+ - \Q$self->{bp}{abstract}\E(?{ \$desc = "POD NAME" })',
                    '\Q$self->{bp}{synopsis}\E(?{ \$desc = "POD SYNOPSIS" })',
                    '\Q$self->{bp}{description}\E(?{ \$desc = "POD DESCRIPTION" })',
                    '\Q$self->{bp}{exports}\E(?{ \$desc = "POD EXPORTS" })',
                    '\Q$self->{bp}{functions}\E(?{ \$desc = "POD SUBROUTINES/METHODS" })',
                    '\Q$self->{bp}{see_also}\E(?{ \$desc = "POD SEE ALSO" })',
                );

            END

        $xt_files{'boilerplate.t'} .= <<~'END';
                foreach ($filename) {
                    if    (/\AREADME\z/)  { push @regex_type, @readme_rgx }
                    elsif (/\AChanges\z/) { push @regex_type, @changes_rgx }
                    elsif (/\.pm\z/)      { push @regex_type, @modules_rgx }
                    else                  { die "$filename is not supported" }
                }

                #p @regex_type;
                #note("\n");

                # Concat and compile the regexes.
                my $joined = join '|', @regex_type;
                my $regex  = qr{^(?> $joined )}mx;

                #note("REGEX:\n");
                #p $regex;
                #note("\n");

                my $c = 0;

                # Scan the file with its respective regex type.
                while (1) {
                    # Boilerplate
                    if ( $file =~ /\G$regex/gc ) {
                        my $end = '';
                        ++$c;

                        note("MATCH:\n$c '$&'\n");
                        fail("$filename contains $desc boilerplate text");

                        # Count lines of a multiline match.
                        my $nl = $& =~ tr{\n}{};
                        if ( $nl > 1 ) {
                            $nl  += $c - 1;
                            $end  = ',' . $nl;
                        }

                        diag("$desc appears on lines ${c}$end");
                        note("\n");

                        $c = $nl;
                    }
                    # Generic line (forwards scanner line-by-line).
                    elsif ( $file =~ /\G([^\n]*+)\n/gc ) {
                        ++$c;
                        #note("$c '$1'");
                    }

                    # End of file.
                    if ( $file =~ /\G\z/ ) {
                        pass("$filename contains no boilerplate text") unless defined $desc;
                        note("\n");

                        last;
                    }
                }
            }

            not_in_file_ok('README');
            not_in_file_ok('Changes');
            END

        $xt_files{'boilerplate.t'} .= <<~"END";
            $module_bp_tests

            T2->done_testing;
            END
    }

    return %xt_files;
}

# Ignore only build files relevant to Unix, EUMM, and the current tooling.
#
# References:
#   https://perlmaven.com/dont-keep-generated-files-in-version-control
sub ignores_guts ( $self, $type )
{
    my $guts = {
        # See:
        #   https://git-scm.com/docs/gitignore
        #   https://github.com/github/gitignore/blob/main/Perl.gitignore
        #   https://github.com/briandfoy/PerlPowerTools/blob/master/.gitignore
        generic => <<~"END",
            MANIFEST
            MANIFEST.bak
            META.*
            MYMETA.*

            # Junk
            *.o
            *.bs
            *.tar
            *.tgz
            *.gz
            *.zip
            *.tmp
            *.old
            *.bak
            *.rej
            *.orig

            # ExtUtils::MakeMaker
            blib/
            Makefile
            Makefile.old
            pm_to_blib

            # Devel::Cover
            cover_db/
            .last_cover_stats

            # Devel::NYTProf
            nytprof.out

            $self->{distro}-*
            END

        # See:
        #   https://metacpan.org/pod/ExtUtils::Manifest#MANIFEST.SKIP
        #   https://neilb.org/2015/10/18/spotters-guide.html#:~:text=MANIFEST.SKIP
        #   https://github.com/briandfoy/PerlPowerTools/blob/master/MANIFEST.SKIP
        manifest => <<~'END',
            # Root allowlist filter
            #
            # NOTE:
            #   Include only specific root dirs or files in the tarball; skip everything else.
            #   This keeps dirs like .github and Markdown files only in version control, e.g.
            #   README.md, docs directory (contains POD files converted to Markdown with pod2markdown).
            \A(?!(?>bin|script|examples|eg|lib|t|xt|share|data)/|(?>Makefile\.PL|README|LICENSE|MANIFEST|Changes|INSTALL|CONTRIBUTING|TODO|SECURITY|META\.(?>json|yml))\z)

            /MANIFEST(?>\.bak)?\z
            /(?>MY)?META\.(?>json|yml)\z

            # Junk
            \.o\z
            \.bs\z
            \.tar\z
            \.tgz\z
            \.gz\z
            \.zip\z
            \.tmp\z
            \.old\z
            \.bak\z
            \.rej\z
            \.orig\z

            # ExtUtils::MakeMaker
            /blib/
            /Makefile(?>\.old)?\z
            /pm_to_blib\z

            # Devel::Cover
            /cover_db/
            /\.last_cover_stats\z

            # Devel::NYTProf
            /nytprof\.out\z

            # git
            /\.git/
            /\.gitignore\z
            END
    };

    # Append regex distro pattern to MANIFEST.SKIP.
    $guts->{manifest} .= "\n/\Q$self->{distro}\E-" . '(?s:.+)\z' . "\n";

    $guts->{hg} = $guts->{cvs} = $guts->{git} = $guts->{generic};

    return $guts->{$type};
}

sub create_file ( $self, $fname, @content )
{
    if ( -f $fname ) {
        if ( !$self->{force} ) {
            warn "Will not overwrite '$fname' (--force option not enabled)";
            return;
        }
    }

    open my $fh, '>', $fname or confess "Can't create $fname: $!\n";
    print $fh @content;
    close $fh or die "Can't close $fname: $!\n";

    return;
}

# Register the default boilerplate texts.
sub _build_boilerplates ($self)
{
    # Use signatures if minimum perl is >= v5.36.0.
    my $use_sig = version->parse( $self->{minperl} ) >= version->parse('v5.36.0');

    # Modules
    {
        $self->{bp}{header} = $self->_get_header;

        $self->{bp}{exports} = <<~'END';
            A list of functions that can be exported. Delete this section if nothing is
            exported, such as for a purely object-oriented module.
            END

        $self->{bp}{stub_function1} = <<~'END';
            sub function1
            {
            }
            END
        $self->{bp}{stub_function1} =~ s{\Asub\ function1\K\n}{ ()\n} if $use_sig;

        $self->{bp}{stub_function2} = <<~'END';
            sub function2
            {
            }
            END
        $self->{bp}{stub_function2} =~ s{\Asub\ function2\K\n}{ ()\n} if $use_sig;

        $self->{bp}{abstract} = 'new abstract';

        $self->{bp}{synopsis} = <<~"END";
            Quick summary of what the module does.

            With brief examples:

                # Procedural

                use $self->{main_module} qw< function >;

                my \$foo = function(...);
                ...

                # OOP

                use $self->{main_module};

                my \$foo = $self->{main_module}->new;
                \$foo->method(...);
                ...
            END

        $self->{bp}{description} = 'Overview or extended description and discussion of the module.';

        $self->{bp}{functions} = <<~'END';
            =head2 function1

            =head2 function2
            END

        $self->{bp}{see_also} = <<~'END';
        =over 4

        =item *

        L<Some::Module>

        =item *

        L<https://some-reference.TLD>

        =back
        END
    }

    # Changes
    {
        $self->{bp}{changelog} = <<~"END";
            $DIST_VERSION    YYYY-MM-DD HH:MM:SSZ
                      - Initial release
            END
    }

    # README
    $self->{bp}{readme_intro} = $self->_README_intro;

    # LICENSE
    $self->{bp}{license} = $self->_get_license;
}

# Returns a header boilerplate; accepts a minimum perl version.
sub _get_header ( $self, $minperl //= $self->{minperl} )
{
    # Fatal warnings are bad, do not use it.
    #my $warnings = sprintf 'warnings%s;', ( $self->{fatalize} ? q{ FATAL => 'all'} : '' );
    my $warnings = 'warnings;';

    # Only declare a minimum perl version if the user wants it.
    $minperl =
      defined $self->{no_minperl} && $self->{no_minperl}
      ? ''
      : "use $minperl;\n\n";

    my $header = $minperl . <<~"END";
        use strict;
        use $warnings

        END

    return $header;
}

# Returns resources metadata information.
sub _get_resources ($self)
{
    my $author     = $self->{github} // $self->{author_name} =~ tr{ }{-}r;
    my $homepage   = '';
    my $repository = "https://github.com/$author/$self->{distro}";
    my $gh_issues  = "$repository/issues";
    my $bug_tracker =
      defined $self->{github}
      ? $gh_issues
      : "https://rt.cpan.org/NoAuth/Bugs.html?Dist=$self->{distro}";

    return {
        repository  => $repository,
        bug_tracker => $bug_tracker,
        homepage    => $homepage,
    };
}

# Returns LICENSE boilerplate; accepts 'POD' argument (if true, returns LICENSE in POD format).
sub _get_license ( $self, %opts )
{
    my $current_year = $self->_thisyear;
    my $name         = $self->{license_record}->spdx_expression // $self->{license};

    $self->{license_record}{holder} = $self->{author_name};

    chomp( my $license = <<~"END" );
        Copyright © $current_year $self->{author_name}
        $name License. See LICENSE for details.
        END

    # Insert blank lines between lines (POD format).
    $license =~ s{
        ^[^\n]+\n
        \K
        (?=
            [^\n]+
            (?> \n | \z)
        )
    }
    {\n}mgx if $opts{POD};

    return $license;
}

=encoding UTF-8

=head1 NAME

Module::Starter::Plugin::MyGuts - module starter with opinionated settings

=head1 SYNOPSIS

In your F<~/.module-starter/config>:

  builder:      ExtUtils::MakeMaker
  license:      MIT_0
  genlicense:   1
  ignores_type: git manifest
  author:       author <author@email>
  minperl:      v5.40.0
  verbose:      1
  plugins:      Module::Starter::Plugin::MyGuts

Then, run:

=for highlighter language=shell

  $ module-starter --module=Foo::Bar

Alternatively:

  $ module-starter \
      --module=Foo::Bar \
      --eumm \
      --license=MIT_0 \
      --genlicense \
      --ignores=git,manifest \
      --author='author <author@email>' \
      --minperl=v5.40.0 \
      --verbose \
      --plugin=Module::Starter::Plugin::MyGuts

=head1 DESCRIPTION

This plugin is a subclass of L<Module::Starter::Simple> that replaces some of its
B<*_guts> methods with my preferred settings, thus not intended for public usage.
Inspired by L<Module::Starter::Plugin::Template>.

Note that only L<ExtUtils::MakeMaker> and single author are supported for simplicity.

=head1 METHODS

=head2 new(I<%args>)

Calls the C<new> C<SUPER> method.

=head2 post_create_distro

If C<github> is set, creates the .github/workflows directory and calls C<create_CI()>,
creates the docs directory (intended to contain POD files from distribution converted
to Markdown), and then calls C<create_README_md()>.

=head2 create_CI ( I<$self, $fpath> )

If C<github> is set, creates the distribution's F<ci.yml> file in .github/workflows
directory.

=head2 create_README_md

If C<github> is set, creates the distribution's F<README.md> file.

=head2 *_guts

These L<Module::Starter::Simple> methods are subclassed to look like this:

=for highlighter language=perl

    sub module_guts ( $self, @args )
    {
        ...
    }

=over 4

=item module_guts

=item Makefile_PL_guts

=item Makefile_PL_meta_merge

=item Changes_guts

=item README_guts

=item t_guts

=item xt_guts

=item ignores_guts

=back

=head2 create_file( I<$fname, @content_lines> )

Overrides C<Module::Starter::Simple::create_file()> so files are created with UTF-8
encoding accordingly.

See L<Module::Starter::Simple/create_file(-$fname,-@content_lines-)>.

=head1 CONFIGURATION

=over 4

=item B<no_minperl>

If true, a minimum perl version is not declared in the files. Default: C<undef>.

=back

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<Module::Starter>

=item *

L<Module::Starter::Simple>

=item *

L<Module::Starter::Plugin::Template>

=item *

L<https://neilb.org/2015/09/05/cpan-glossary.html>

=item *

L<https://neilb.org/2015/10/18/spotters-guide.html>

=item *

L<https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/cpan-packaging.md>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut
