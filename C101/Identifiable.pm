package C101::Identifiable;
use feature 'state';
use Data::UUID;
use Moose;

has 'uuid' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => \&_create_uuid,
);

sub renew_uuid {
    my $self = shift;
    my $old  = $self->uuid;
    $self->{uuid} = _create_uuid();
    return $old;
}

sub _create_uuid {
    state $ug = new Data::UUID;
    return $ug->create_str();
}

1;
__END__

=head2 C101::Identifiable

Base class for Companies, Departments and Employees. Gives the object a UUID (universally
unique identifier) when it is constructed. UUIDs are represented as strings.

=head3 Properties

=over 4

=item uuid (Str, read-only)

A UUID for the object. A new UUID will be generated if none is given to the constructor.

=back

=head3 renew_uuid($self)

Creates and sets new UUID for this object. The old UUID is returned.

=cut

