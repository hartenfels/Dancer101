package C101;
use Moops;

class Validator {
    use Scalar::Util qw(looks_like_number);

    has 'forms' => (
        is       => 'ro',
        isa      => 'HashRef',
        required => 1,
    );

    my %validators = (
        Str         => fun($val) {
            $val =~ s/^\s*|\s*$//g;
            $val =~ /\S/ or return (0, "This can't be empty.");
            return (1, "$val");
        },
        Num         => fun($val) {
            looks_like_number($val) or return (0, "That's not a number.");
            return (1, $val + 0);
        },
        UnsignedNum => fun($val) {
            looks_like_number($val) && $val >= 0
                or return (0, "That's not an unsigned number.");
            return (1, $val + 0);
        },
    );

    method validate(Str $what, HashRef $fields) {
        my $form  = $self->forms->{$what} or die "Don't know form ``$what''";
        my (%results, %errors);
        for my $f (@{$form->{fields}}) {
            my $key        = $f->{name};
            my ($ok, $res) = $validators{$f->{type}}->($fields->{$key});
            if ($ok) {
                $results{$key} = $res;
            } else {
                $errors{$key}  = $res;
            }
        }
        return (!%errors, %errors ? \%results : \%errors);
    }

}

__END__

=head2 Validator

=cut
