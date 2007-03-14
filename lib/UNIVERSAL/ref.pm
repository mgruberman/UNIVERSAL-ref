package UNIVERSAL::ref;
use strict;
use warnings;
use B::Utils;

our %hooked = ( overload => undef );

sub import {
    $hooked{ caller() } = undef;
}

sub unimport {
    delete $hooked{ caller() };
}

our $VERSION = '0.08';
use XSLoader;
XSLoader::load( 'UNIVERSAL::ref', $VERSION );

my %roots = B::Utils::all_roots();
for my $nm ( sort keys %roots ) {
    my $op = $roots{$nm};

    #    syswrite STDOUT, "$nm=$op\n";

    next unless $$op;
    next if $nm eq 'UNIVERSAL::ref::hook';

    fixupop($op);
}

sub hook {
    return ref $_[0] if 'overload' eq caller;
    return ref $_[0] if exists $hooked{ caller() };

    #    syswrite STDOUT, "OVERLOADING for ".caller()."\n";
    return scalar $_[0]->ref;
}

q[Let's Make Love and Listen to Death From Above];

__END__

=head1 NAME

UNIVERSAL::ref - Turns ref() into a multimethod

=head1 SYNOPSIS

  # True! Wrapper pretends to be Thing.
  ref( Wrapper->new( Thing->new ) )
    eq ref( Thing->new );

  package Thing;
  sub new { bless [], shift }

  package Wrapper;
  sub new {
      my ($class,$proxy) = @_;
      bless \ $proxy, $class;
  }
  sub ref {
      my $self = shift @_;
      return $$self;
  }

=head1 DESCRIPTION

This module changes the behavior of the builtin function ref(). If
ref() is called on an object that has requested an overloaded ref, the
object's C<< ->ref >> method will be called and its return value used
instead.

=head1 USING

To enable this feature for a class, C<use UNIVERSAL::ref> in your
class. Here is a sample proxy module.

  package Pirate;
  # Pirate pretends to be a Privateer
  use UNIVERSAL::ref;
  sub new { bless {}, shift }
  sub ref { return 'Privateer' }

Anywhere you call C<ref($obj)> on a C<Pirate> object, it will allow
C<Pirate> to lie and pretend to be something else.

=head1 TODO

Currently UNIVERSAL::ref must be installed before any ref() calls that
are to be affected.

I think ref() always occurs in an implicit scalar context. There is no
accomodation for list context.

UNIVERSAL::ref probably shouldn't allow a module to lie to itself. Or
should it?

=head1 ACKNOWLEDGEMENTS

ambrus for the excellent idea to overload defined() to allow Perl 5 to
have Perl 6's "interesting values of undef."

chromatic for pointing out how utterly broken ref() is. This fix
covers its biggest hole.

=head1 AUTHOR

Joshua ben Jore - jjore@cpan.org

=head1 LICENSE

The standard Artistic / GPL license most other perl code is typically
using.
