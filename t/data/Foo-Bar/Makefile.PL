use v5.40.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Foo::Bar',
    AUTHOR           => q{author <author@email>},
    VERSION_FROM     => 'lib/Foo/Bar.pm',
    ABSTRACT_FROM    => 'lib/Foo/Bar.pm',
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => 'v5.40.0',
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
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => {
            directory => [
                qw<
                    eg
                    examples
                    share
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
                    'Devel::NYTProf'    => '0',
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
                url  => 'https://github.com/author/Foo-Bar.git',
                web  => 'https://github.com/author/Foo-Bar',
            },
            bugtracker => {
                web => 'https://github.com/author/Foo-Bar/issues',
            },
            #homepage => '',
            #'x_IRC' => {
            #    url => 'irc://irc.libera.chat/#channel',
            #    web => 'https://web.libera.chat/?nick=Guest?#channel',
            #}
        },
        x_contributors => [
            q{author <author@email>},
        ],
        x_spdx_expression => 'MIT-0',
    },
);

WriteMakefile(%WriteMakefileArgs);
