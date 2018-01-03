
use Jojo::Base -strict;

use Test::More;

package Mojo::BaseTest {
  use Jojo::Base -base;
  BEGIN { our $VERSION = '2' }
}

package Mojo::BaseTestTest {
  use Jojo::Base 'Mojo::BaseTest~1';
  BEGIN { our $VERSION = 2 }
}

package Mojo::BaseTestTestTest {
  use Jojo::Base 'Mojo::BaseTestTest~1.5.3';
  BEGIN { our $VERSION = 2 }
}

isa_ok 'Mojo::BaseTestTest',     'Mojo::BaseTest';
isa_ok 'Mojo::BaseTestTestTest', 'Mojo::BaseTestTest';
isa_ok 'Mojo::BaseTestTestTest', 'Mojo::BaseTest';

done_testing;
