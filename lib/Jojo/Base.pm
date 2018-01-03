
package Jojo::Base;

# ABSTRACT: Mojo::Base + lexical "has"
use 5.018;
use strict;
use warnings;
use utf8;
use feature      ();
use experimental ();

BEGIN {
  require Mojo::Base;
  our @ISA = qw(Mojo::Base);
}

use Carp             ();
use Module::Spec::V1 ();
use Mojo::Util       ();
use Sub::Inject 0.2.0 ();

use constant ROLES => !!Module::Spec::V1::try_module('Jojo::Role~0.4.0');

use constant SIGNATURES => ($] >= 5.020);

our %EXPORT_TAGS;
our %EXPORT_GEN;

sub import {
  my $class = shift;
  return unless my $flag = shift;
  my $caller = caller;

  # Base
  my $base;
  if ($flag eq '-base') { $base = $class }

  # Strict
  elsif ($flag eq '-strict') { }

  # Role
  elsif ($flag eq '-role') {
    Carp::croak 'Jojo::Role 0.4.0+ is required for roles' unless ROLES;
    Jojo::Role->_become_role($caller);
  }

  # Module
  elsif (($base = $flag) && ($flag = '-base')) {

    state $_NEED_OPTS = {require => sub { !shift->can('new') },};
    $base = Module::Spec::V1::need_module($base, $_NEED_OPTS);
  }

  # Jojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.18');
  experimental->import('lexical_subs');

  # Signatures (Perl 5.20+)
  if ((shift || '') eq '-signatures') {
    Carp::croak 'Subroutine signatures require Perl 5.20+' unless SIGNATURES;
    experimental->import('signatures');
  }

  # ISA
  if ($base) {
    no strict 'refs';
    push @{"${caller}::ISA"}, $base;
  }

  my @exports = @{$EXPORT_TAGS{$flag} // []};
  if (@exports) {
    @_ = $class->_generate_subs($caller, @exports);
    goto &Sub::Inject::sub_inject;
  }
}

sub role_provider {'Jojo::Role'}

sub with_roles {
  Carp::croak 'Jojo::Role 0.4.0+ is required for roles' unless ROLES;
  my ($self, @roles) = @_;

  return Jojo::Role->create_class_with_roles($self, @roles)
    unless my $class = Scalar::Util::blessed $self;

  return Jojo::Role->apply_roles_to_object($self, @roles);
}

BEGIN {
  %EXPORT_TAGS = (-base => [qw(has with)], -role => [qw(has)], -strict => [],);

  %EXPORT_GEN = (
    has => sub {
      my (undef, $target) = @_;
      return sub { Mojo::Base::attr($target, @_) }
    },
    with => sub {    # dummy
      return sub { Carp::croak 'Jojo::Role 0.4.0+ is required for roles' }
    },
  );

  return unless ROLES;

  push @{$EXPORT_TAGS{-role}}, @{$Jojo::Role::EXPORT_TAGS{-role}};

  $EXPORT_GEN{$_} = $Jojo::Role::EXPORT_GEN{$_}
    for @{$Jojo::Role::EXPORT_TAGS{-role}};
}

sub _generate_subs {
  my ($class, $target) = (shift, shift);
  return map { my $cb = $EXPORT_GEN{$_}; $_ => $class->$cb($target) } @_;
}

1;

=encoding utf8

=head1 SYNOPSIS

  package Cat {
    use Jojo::Base -base;    # requires perl 5.18+

    has name => 'Nyan';
    has ['age', 'weight'] => 4;
  }

  package Tiger {
    use Jojo::Base 'Cat';

    has friend => sub { Cat->new };
    has stripes => 42;
  }

  package main;
  use Jojo::Base -strict;

  my $mew = Cat->new(name => 'Longcat');
  say $mew->age;
  say $mew->age(3)->weight(5)->age;

  my $rawr = Tiger->new(stripes => 38, weight => 250);
  say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

=head1 DESCRIPTION

L<Jojo::Base> works kind of like L<Mojo::Base> but C<has> is imported
as lexical subroutine.

L<Jojo::Base>, like L<Mojo::Base>, is a simple base class designed
to be effortless and powerful.

  # Enables "strict", "warnings", "utf8" and Perl 5.18 and "lexical_subs" features
  use Jojo::Base -strict;
  use Jojo::Base -base;
  use Jojo::Base 'SomeBaseClass';
  use Jojo::Base -role;

All four forms save a lot of typing. Note that role support depends on
L<Jojo::Role> (0.4.0+).

  # use Jojo::Base -strict;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();

  # use Jojo::Base -base;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();
  push @ISA, 'Jojo::Base';
  state sub has { ... }    # attributes
  state sub with { ... }   # role composition

  # use Jojo::Base 'SomeBaseClass';
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();
  require SomeBaseClass;
  push @ISA, 'SomeBaseClass';
  state sub has { ... }    # attributes
  state sub with { ... }   # role composition

  # use Jojo::Base -role;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();
  use Jojo::Role;
  state sub has { ... }    # attributes

On Perl 5.20+ you can also append a C<-signatures> flag to all four forms and
enable support for L<subroutine signatures|perlsub/"Signatures">.

  # Also enable signatures
  use Jojo::Base -strict, -signatures;
  use Jojo::Base -base, -signatures;
  use Jojo::Base 'SomeBaseClass', -signatures;
  use Jojo::Base -role, -signatures;

This will also disable experimental warnings on versions of Perl where this
feature was still experimental.

=head2 DIFFERENCES FROM C<Mojo::Base>

=over 4

=item *

All functions are exported as lexical subs

=item *

Role support depends on L<Jojo::Role> instead of L<Role::Tiny>

=item *

C<with> is exported alongside C<has> (when L<Jojo::Role> is available)

=item *

Feature bundle for Perl 5.18 is enabled by default, instead of 5.10

=item *

Support for L<lexical subroutines|perlsub/"Lexical Subroutines"> is enabled
by default

=item *

L<Module specs|Module::Spec::V1> (such as C<SomeModule~2.3>) are accepted to specify base classes.

=item *

Single quotes (C<'>) are not accepted as package separators.

=back

=head1 FUNCTIONS

L<Jojo::Base> implements the following functions, which can be imported with
the C<-base> flag, or by setting a base class.

=head2 has

  has 'name';
  has ['name1', 'name2', 'name3'];
  has name => 'foo';
  has name => sub {...};
  has ['name1', 'name2', 'name3'] => 'foo';
  has ['name1', 'name2', 'name3'] => sub {...};

Create attributes for hash-based objects, just like the L<Mojo::Base/"attr"> method.

=head2 with

  with 'SubClass::Role::One';
  with '+One', '+Two';

Composes the current package with one or more L<Jojo::Role> roles.
For roles following the naming scheme C<MyClass::Role::RoleName> you
can use the shorthand C<+RoleName>. Note that role support depends on
L<Jojo::Role> (0.4.0+).

It works with L<Jojo::Role> or L<Role::Tiny> roles.

=head1 METHODS

L<Jojo::Base> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 with_roles

  my $new_class = SubClass->with_roles('SubClass::Role::One');
  my $new_class = SubClass->with_roles('+One', '+Two');
  $object       = $object->with_roles('+One', '+Two');

Create a new class with one or more roles. If called on a class
returns the new class, or if called on an object reblesses the object into the
new class. For roles following the naming scheme C<MyClass::Role::RoleName> you
can use the shorthand C<+RoleName>. Note that role support depends on
L<Jojo::Role> (0.4.0+).

  # Create a new class with the role "SubClass::Role::Foo" and instantiate it
  my $new_class = SubClass->with_roles('+Foo');
  my $object    = $new_class->new;

It works with L<Jojo::Role> or L<Role::Tiny> roles.

=head1 CAVEATS

=over 4

=item *

L<Jojo::Base> requires perl 5.18 or newer

=item *

Because a lexical sub does not behave like a package import,
some code may need to be enclosed in blocks to avoid warnings like

    "state" subroutine &has masks earlier declaration in same scope at...

=back

=head1 SEE ALSO

L<Mojo::Base>, L<Jojo::Role>.

=head1 ACKNOWLEDGMENTS

Thanks to Sebastian Riedel and others, the authors
and copyright holders of L<Mojo::Base>.

=cut
