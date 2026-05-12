#!perl

use v5.40.0;

use strict;
use warnings;

use Test2::V1 qw< like dies >;
T2->plan(2);

use Module::Starter::Plugin::MyGuts;

like(
    dies {
        Module::Starter::Plugin::MyGuts->new( builder => [ qw< Module::Build > ] );
    },
    qr/\AOnly ExtUtils::MakeMaker is supported /,
    'got exception (builder is not ExtUtils::MakeMaker)',
);

like(
    dies {
        Module::Starter::Plugin::MyGuts->new( builder => [ qw< ExtUtils::MakeMaker Module::Build > ] );
    },
    qr/\AOnly one builder is supported /,
    'got exception (multiple builders are not supported)',
);
