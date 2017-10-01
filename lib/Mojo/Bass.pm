
package Mojo::Bass;

use 5.018;
use Mojo::Base -strict;

BEGIN {
  our @ISA = qw(Mojo::Base);
}

use Sub::Inject 0.2.0 ();

sub import {
  my $class = shift;
  return unless my $flag = shift;

  # Base
  if ($flag eq '-base') { $flag = $class }

  # Strict
  elsif ($flag eq '-strict') { $flag = undef }

  # Module
  elsif ((my $file = $flag) && !$flag->can('new')) {
    $file =~ s!::|'!/!g;
    require "$file.pm";
  }

  # Mojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');

  # ISA
  if ($flag) {
    my $caller = caller;
    no strict 'refs';
    push @{"${caller}::ISA"}, $flag;
    @_ = ($caller, has => sub { Mojo::Base::attr($caller, @_) });
    goto &{$class->can('_export_into')};
  }
}

sub _export_into {
  shift;
  goto &Sub::Inject::sub_inject;
}

1;

=encoding utf8

=head1 NAME

Mojo::Bass - Mojo::Base + lexical "has"

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
