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
            return (0, "This can't be empty.") if $val !~ /\S/;
            return (1, "$val");
        },
        UnsignedNum => fun($val) {
            return (0, "That's not a number.") if not looks_like_number($val);
            return (0, "This can't be negative.") if $val < 0;
            return (1, $val + 0);
        },
    );

    method validate(Str $key, Map[Str, Str] $fields) {
        my $form  = $self->forms->{$key} or die "Don't know form ``$key''";
        my $valid = 1;
        my (%results, %errors);
        for my $f (@$form) {
            my $key        = $f->{name};
            my ($ok, $res) = $validators{$f->{type}}->($fields->{$key});
            if ($valid &&= $ok) {
                $results{$key} = $res;
            } else {
                $errors{$key}  = $res;
            }
        }
        return ($valid, $valid ? \%results : \%errors);
    }

}

__END__

=head1 Validator

=cut
