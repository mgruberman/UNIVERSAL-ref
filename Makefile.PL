use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'UNIVERSAL::ref',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    VERSION_FROM  => 'lib/UNIVERSAL/ref.pm',
    ABSTRACT_FROM => 'lib/UNIVERSAL/ref.pm',
    PREREQ_PM     => { 'Test::More' => 0, },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'UNIVERSAL-ref-*' },
);

do 'Bastard.PL';
