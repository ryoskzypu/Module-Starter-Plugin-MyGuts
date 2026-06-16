use v5.40.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Module::Starter::Plugin::MyGuts',
    AUTHOR             => q{ryoskzypu <ryoskzypu@proton.me>},
    VERSION_FROM       => 'lib/Module/Starter/Plugin/MyGuts.pm',
    ABSTRACT_FROM      => 'lib/Module/Starter/Plugin/MyGuts.pm',
    LICENSE            => 'open_source',
    MIN_PERL_VERSION   => 'v5.40.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'File::Basename'           => '0',
        'File::Spec::Functions'    => '0',
        'File::Temp'               => '0',
        'Software::License::MIT_0' => 'v1.0.0',
        'Test2::Plugin::UTF8'      => '0',
        'Test2::V1'                => '0',
        'Text::Diff'               => '1.45',
    },
    PREREQ_PM => {
        'Carp'                    => '0',
        'File::Path'              => '0',
        'File::Spec'              => '0',
        'Module::Starter'         => '1.82',
        'Module::Starter::Simple' => '1.82',
    },
    META_MERGE => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 0,
        no_index       => {
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
            runtime => {
                recommends => {
                    'App::pod2gfm'             => 'v1.0.0',
                    'Software::License::MIT_0' => 'v1.0.0',
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts.git',
                web  => 'https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts',
            },
            bugtracker => {
                web => 'https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts/issues',
            },
        },
        x_contributors => [
            q{ryoskzypu <ryoskzypu@proton.me>},
        ],
        x_spdx_expression => 'MIT-0',
    },
);

WriteMakefile(%WriteMakefileArgs);
