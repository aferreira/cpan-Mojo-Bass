
package Mojo::Bass;

# ABSTRACT: Mojo::Base + lexical "has"
use 5.018;
use Mojo::Base -strict;

use Carp ();

BEGIN {
  our @ISA = qw(Mojo::Base);
}

use Sub::Inject 0.2.0 ();

use constant ROLES => Mojo::Base::ROLES;

use constant SIGNATURES => ($] >= 5.020);

sub import {
  my ($class, $caller) = (shift, caller);
  return unless my $flag = shift;

  my @exports = ('has');

  # Base
  my $base;
  if ($flag eq '-base') { $base = $class }

  # Strict
  elsif ($flag eq '-strict') { @exports = () }

  # Role
  elsif ($flag eq '-role') {
    Carp::croak 'Role::Tiny 2.000001+ is required for roles' unless ROLES;
    eval "package $caller; use Role::Tiny; 1" or die $@;
  }

  # Module
  elsif (($base = $flag) && !$base->can('new')) {
    (my $file = $base) =~ s!::|'!/!g;
    require "$file.pm";
  }

  # Mojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');

  # Signatures (Perl 5.20+)
  if ((shift || '') eq '-signatures') {
    Carp::croak 'Subroutine signatures require Perl 5.20+' unless SIGNATURES;
    require experimental;
    experimental->import('signatures');
  }

  # ISA
  if ($base) {
    no strict 'refs';
    push @{"${caller}::ISA"}, $base;
  }

  if (@exports) {
    @_ = (has => sub { Mojo::Base::attr($caller, @_) });
    goto &Sub::Inject::sub_inject;
  }
}

1;

=encoding utf8

=head1 SYNOPSIS

  package Cat {
    use Mojo::Bass -base;

    has name => 'Nyan';
    has ['age', 'weight'] => 4;
  }

  package Tiger {
    use Mojo::Bass 'Cat';

    has friend => sub { Cat->new };
    has stripes => 42;
  }

  package main;
  use Mojo::Bass -strict;

  my $mew = Cat->new(name => 'Longcat');
  say $mew->age;
  say $mew->age(3)->weight(5)->age;

  my $rawr = Tiger->new(stripes => 38, weight => 250);
  say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

=head1 DESCRIPTION

L<Mojo::Bass> works like L<Mojo::Base> but C<has> is imported
as lexical subroutine.

=head1 CAVEATS

=over 4

=item *

L<Mojo::Bass> requires perl 5.18 or newer

=item *

Because a lexical sub does not behave like a package import,
some code may need to be enclosed in blocks to avoid warnings like

    "state" subroutine &has masks earlier declaration in same scope at...

=back

=head1 SEE ALSO

L<Mojo::Base>.

=cut
