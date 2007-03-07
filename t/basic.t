#!perl
use strict;
use warnings;
use Test::More;
use vars '$TESTS';

# # ok( not( defined undef ), 'undef is undefined' );
# # ok( defined 1,            '1 is defined' );
# # ok( defined '...',        '"..." is defined' );
# # ok( defined [], '[] is defined' );
# #
# # sub X1::defined {1}
# # sub X2::defined {0}
# # ok( defined( bless [], 'X1' ), 'X1 is defined because ->defined is true' );
# # ok( not( defined bless [], 'X2' ),
# #     'X2 is not defined because ->defined is false' );
# #
# # sub Y::defined { }
# # ok( not( defined bless [], 'Y' ),
# #     'Y is not defined because ->defined returned empty' );
# #
# # sub Z::defined { return ( 0, 0 ) }
# # ok( not( defined bless [], 'Z' ), q[Z returned (0,0) so it is undefined] );
# #
# # ok( defined( bless [], 'A' ), 'A has no ->defined method so it is fine' );
#

{
    BEGIN { $TESTS += 1 }

    package LIAR;
    use UNIVERSAL::ref;
    sub ref {'lie'}

    package main;

    # Validate that ref() lies for us.
    ::is( CORE::ref( bless [], 'LIAR' ), 'lie', 'Basic overloading' );
}

{
    BEGIN { $TESTS += 3 }

    # Validate that ref() works as normal for non-hooked things.
    is( ref(''), '', q[ref('')] );
    is( ref( [] ), 'ARRAY', q[ref([])] );
    is( ref( bless [], 'A1' ), 'A1', q[ref(obj)] );
}

{
    BEGIN { $TESTS += 2 }

    package DELUSION;
    use UNIVERSAL::ref;
    sub ref    {'blah blah blah'}
    sub myself { CORE::ref $_[0] }

    ::is( bless( [], 'DELUSION' ), 'blah blah blah' );
    ::is( bless( [], 'DELUSION' )->myself, 'DELUSION' );
}

{
    BEGIN { $TESTS += 2 }

    package OVERLOADED;
    sub ref {'NOT-OVERLOADED'}
    use overload 'bool' => 'FALSE';
    use UNIVERSAL::ref;

    package main;
    my $obj = bless [], 'OVERLOADED';
    ok( overload::Overloaded($obj),
        'Overloaded objects still look overloaded' );
    like(
        overload::StrVal($obj),
        qr/\A\QOVERLOADED::ARRAY=(0x\E[\da-fA-F]+\)\z/,
        'Overloaded objects stringify normally too'
    );
}

{
    BEGIN { $TESTS += 1 }

    package PAST;
    use UNIVERSAL::ref;
    sub ref {'PAST'}

    package main;
    is( ref( bless [], 'PAST' ), 'lie',
        'UNIVERSAL::ref fixes the past too.' );
}

BEGIN { plan( tests => $TESTS ) }
