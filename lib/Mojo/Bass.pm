
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

use constant EXPORTS_FOR => {
  -base => [ROLES ? qw(has with) : qw(has)],
  -role => [qw(has)],
  -strict => [],
};

sub import {
  my ($class, $caller) = (shift, caller);
  return unless my $flag = shift;

  # Base
  my $base;
  if ($flag eq '-base') { $base = $class }

  # Strict
  elsif ($flag eq '-strict') { }

  # Role
  elsif ($flag eq '-role') {
    Carp::croak 'Role::Tiny 2.000001+ is required for roles' unless ROLES;
    eval "package $caller; use Role::Tiny; 1" or die $@;
  }

  # Module
  elsif (($base = $flag) && ($flag = '-base') && !$base->can('new')) {
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

  my $exports = EXPORTS_FOR->{$flag};
  if (@$exports) {
    @_ = $class->_generate_subs($caller, @$exports);
    goto &Sub::Inject::sub_inject;
  }
}

our %EXPORT_GEN = (
  has => sub {
    my (undef, $target) = @_;
    return sub { Mojo::Base::attr($target, @_) }
  },
  with => sub {
    my (undef, $target) = @_;
    return sub { Role::Tiny->apply_roles_to_package($target, @_) }
  },
);

sub _generate_subs {
  my ($class, $target) = (shift, shift);
  return map { my $cb = $EXPORT_GEN{$_}; $_ => $class->$cb($target) } @_;
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
