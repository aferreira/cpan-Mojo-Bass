
BEGIN {
    require Jojo::Base;
    *Mojo::Bass:: = *Jojo::Base::;
}

package Mojo::Bass;

# ABSTRACT: DEPRECATED! Mojo::Base + lexical "has"

1;

=encoding utf8

=head1 DESCRIPTION

DEPRECATED! Use L<Jojo::Base> instead.

=head1 SEE ALSO

L<Jojo::Base>.

=cut
