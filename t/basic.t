#!perl
use strict;
use warnings;
use Test::More 'no_plan';

# ok( not( defined undef ), 'undef is undefined' );
# ok( defined 1,            '1 is defined' );
# ok( defined '...',        '"..." is defined' );
# ok( defined [], '[] is defined' );
#
# sub X1::defined {1}
# sub X2::defined {0}
# ok( defined( bless [], 'X1' ), 'X1 is defined because ->defined is true' );
# ok( not( defined bless [], 'X2' ),
#     'X2 is not defined because ->defined is false' );
#
# sub Y::defined { }
# ok( not( defined bless [], 'Y' ),
#     'Y is not defined because ->defined returned empty' );
#
# sub Z::defined { return ( 0, 0 ) }
# ok( not( defined bless [], 'Z' ), q[Z returned (0,0) so it is undefined] );
#
# ok( defined( bless [], 'A' ), 'A has no ->defined method so it is fine' );

TODO: {
    local $TODO = q[Can't fix the past];
    is( ref( bless [], 'Liar' ), 'lie',
        'UNIVERSAL::ref fixes the past too.' );
}

{

    package Liar;
    use UNIVERSAL::ref;
    sub ref {'lie'}
}

# Validate that ref() lies for us.
is( ref( bless [], 'Liar' ), 'lie', 'Basic overloading' );

# Validate that ref() works as normal for non-hooked things.
is( ref(''), '', q[ref('')] );
is( ref( [] ), 'ARRAY', q[ref([])] );
is( ref( bless [], 'A1' ), 'A1', q[ref(obj)] );

{

    package Liar2;
    use UNIVERSAL::ref;
    use Scalar::Util 'blessed';
    sub ref {'lie'}
    sub foo { return blessed( $_[0] ) }
}

# Validate that ref() doesn't allow us to lie to ourselves.
is( ref( bless [], 'Liar2' ), 'lie' );
is( bless( [], 'Liar2' )->foo, 'Liar2' );

# Do something sane for list context.
TODO: {
    local $TODO = q[No support for list context context];
    sub ListLiar::ref { return ( 'a', 'b' ) }
    is_deeply(
        [ ref( bless [], 'ListLiar' ) ],
        [ 'a', 'b' ],
        'Did the right thing in list context'
    );
}
