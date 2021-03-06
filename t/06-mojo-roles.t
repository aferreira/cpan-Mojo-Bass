use Jojo::Base -strict;

use Test::More;

BEGIN {
  plan skip_all => 'Jojo::Role 0.5.0+ required for this test!'
    unless Jojo::Base->ROLES;
}

package Mojo::RoleTest::Role::LOUD;
use Jojo::Role;

sub yell {'HEY!'}

requires 'name';

sub hello {
  my $self = shift;
  return $self->yell . ' ' . uc($self->name) . '!!!';
}

package Mojo::RoleTest::Role::quiet {
  use Jojo::Base -role;

  requires 'name';

  has prefix => 'psst, ';

  sub whisper {
    my $self = shift;
    return $self->prefix . lc($self->name);
  }
}

package Mojo::RoleTest {
  use Jojo::Base -base;

  has name => 'bob';

  sub hello {
    my ($self) = shift;
    return 'hello ' . $self->name;
  }
}

package Mojo::RoleTest::Hello {
  use Jojo::Base -role;

  sub hello {'hello mojo!'}
}

package main;

use Mojo::ByteStream;
use Mojo::Collection;
use Mojo::DOM;
use Mojo::File;

# Plain class
my $obj = Mojo::RoleTest->new(name => 'Ted');
is $obj->name,  'Ted',       'attribute';
is $obj->hello, 'hello Ted', 'method';

# Single role
my $obj2 = Mojo::RoleTest->with_roles('Mojo::RoleTest::Role::LOUD')->new;
is $obj2->hello, 'HEY! BOB!!!', 'role method';
is $obj2->yell,  'HEY!',        'another role method';

# Single role (shorthand)
my $obj4 = Mojo::RoleTest->with_roles('+LOUD')->new;
is $obj4->hello, 'HEY! BOB!!!', 'role method';
is $obj4->yell,  'HEY!',        'another role method';

# Multiple roles
my $obj3 = Mojo::RoleTest->with_roles('Mojo::RoleTest::Role::quiet',
  'Mojo::RoleTest::Role::LOUD')->new(name => 'Joel');
is $obj3->name,    'Joel',       'base attribute';
is $obj3->whisper, 'psst, joel', 'method from first role';
$obj3->prefix('psssst, ');
is $obj3->whisper, 'psssst, joel', 'method from first role';
is $obj3->hello,   'HEY! JOEL!!!', 'method from second role';

# Multiple roles (shorthand)
my $obj5 = Mojo::RoleTest->with_roles('+quiet', '+LOUD')->new(name => 'Joel');
is $obj5->name,    'Joel',         'base attribute';
is $obj5->whisper, 'psst, joel',   'method from first role';
is $obj5->hello,   'HEY! JOEL!!!', 'method from second role';

# Multiple roles (mixed)
my $obj6 = Mojo::RoleTest->with_roles('Mojo::RoleTest::Role::quiet', '+LOUD')
  ->new(name => 'Joel');
is $obj6->name,    'Joel',         'base attribute';
is $obj6->whisper, 'psst, joel',   'method from first role';
is $obj6->hello,   'HEY! JOEL!!!', 'method from second role';

# Multiple object roles (mixed)
my $obj7 = Mojo::RoleTest->new(name => 'Joel')
  ->with_roles('Mojo::RoleTest::Role::quiet', '+LOUD');
is $obj7->name,    'Joel',         'base attribute';
is $obj7->whisper, 'psst, joel',   'method from first role';
is $obj7->hello,   'HEY! JOEL!!!', 'method from second role';

# Classes that are not subclasses of Mojo::Base
my $stream = Mojo::ByteStream->with_roles('Mojo::RoleTest::Hello')->new;
is $stream->hello, 'hello mojo!', 'right result';
my $c = Mojo::Collection->with_roles('Mojo::RoleTest::Hello')->new;
is $c->hello, 'hello mojo!', 'right result';
my $dom = Mojo::DOM->with_roles('Mojo::RoleTest::Hello')->new;
is $dom->hello, 'hello mojo!', 'right result';
my $file = Mojo::File->with_roles('Mojo::RoleTest::Hello')->new;
is $file->hello, 'hello mojo!', 'right result';

done_testing();

