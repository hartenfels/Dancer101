package C101::Identifiable;
use feature 'state';
use Data::UUID;
use Moose;

has 'uuid' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => sub {
        state $ug = new Data::UUID;
        return $ug->create_str();
    },
);

1;

