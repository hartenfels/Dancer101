package C101;
use feature qw(switch);
use Moops;

class Server {
    use Dancer;
    use Data::Structure::Util qw(unbless);
    use JSON::XS              qw(encode_json);
    use Scalar::Util          qw(looks_like_number);
    use Storable              qw(dclone);
    use Template;
    use C101::Operations      qw(remove uuids);
    use C101::Persistence     qw(serialize unserialize unparse);
    use C101::Sample;

    has 'companies' => (
        is       => 'ro',
        isa      => 'ArrayRef[C101::Company]',
        required => 1,
        default  => sub {
            -e 'companies.bin' ? unserialize('companies.bin') : [ C101::Sample::create ]
        },
    );

    has '_uuids' => (
        is       => 'rw',
        isa      => 'HashRef[C101::Model]',
    );

    method BUILD { $self->_uuids(uuids(@{$self->companies})) }

    method save { serialize($self->companies, 'companies.bin') }

    method _uuid(Str $key, $value?) {
        if (!defined $value) {
            $self->_uuids->{$key};
        } elsif (!$value) {
            delete $self->_uuids->{$key};
        } else {
            $self->_uuids->{$key} = $value;
        }
    }


    method _jsonify(%thing) {
        content_type('application/json');
        encode_json(\%thing);
    }

    method _get($file, @args) {
        if (request->is_ajax) {
            $self->_jsonify(
                messages => _messages(),
                type     => 'get',
                html     => template($file => {@args}),
            );
        } else {
            content_type('text/html');
            template $file => {@args, messages => _messages()};
        }
    }

    method _success {
        if (request->is_ajax) {
            $self->_jsonify(
                messages  => _messages(),
                type      => 'success',
                companies => unbless(dclone($self->companies)),
            );
        } else {
            redirect '/';
        }
    }

    method _failure {
        if (request->is_ajax) {
            $self->_jsonify(
                messages => _messages(),
                type     => 'failure',
            );
        } else {
            redirect '/';
        }
    }


    method handle_index {
        return $self->_get('index.tt',
            title     => 'Contribution:Dancer',
            companies => $self->companies,
        );
    };

    method handle_add(HashRef $args) {
        my $type   = $args->{type};
        my $uuid   = param('uuid');
        my $list   = $args->{list};
        my $parent = $uuid ? $self->_uuid($uuid) : undef;

        if ($list && !$parent) {
            _set_error("The UUID $uuid does not correspond to anything. Either you "
                     . 'accessed a broken link or the object was modified.');
            return $self->_failure;
        }

        if (request->method eq 'POST') {
            my $valid = _validate($args->{validate});
            if (defined $valid) {
                my $obj = eval { "C101::$type"->new($valid) };
                if ($@) {
                    $@ =~ /^([^\n]*)/;
                    _set_error("Error: $1");
                } else {
                    push(($list ? $parent->$list : $self->companies), $obj);
                    $self->_uuid($obj->uuid => $obj);
                    _set_message("Created $type ${\$obj->name}.");
                    return $self->_success;
                }
            }
        }

        return $self->_get('form.tt',
            title => $list ? "Add $type to ${\$parent->name}" : "Create $type",
            url   => request->uri,
            _entries($args->{validate}),
        );
    }

    method handle_edit(HashRef $args) {
        my $type = $args->{type};
        my $uuid = param('uuid');
        my $obj  = $uuid ? $self->_uuid($uuid) : undef;

        if (!$obj || !$obj->isa("C101::$type")) {
            _set_error("The UUID $uuid does not correspond to any $type. "
                      . 'Either you accessed a broken link or the object was modified.');
            return $self->_failure;
        }

        if (request->method eq 'POST') {
            my $valid = _validate($args->{validate});
            if (defined $valid) {
                my $old = {};
                eval {
                    while (my ($k, $v) = each($valid)) {
                        $old->{$k} = $obj->$k;
                        $obj->$k($v);
                    }
                };
                if ($@) {
                    $@ =~ /^([^\n]*)/;
                    _set_error("Error: $1");
                    # attempt to restore old values
                    while (my ($k, $v)) {
                        eval { $obj->$k($old->{$k}) if $old->{$k} };
                    }
                } else {
                    _set_message("Modified $type ${\$obj->name}.");
                    return $self->_success;
                }
            }
        }

        return $self->_get('form.tt',
            title => sprintf($args->{title}, $obj->name),
            url   => request->uri,
            _entries($args->{validate}, $obj),
        );
    }

    method handle_delete {
        my $uuid = param('uuid');
        my $obj  = $uuid ? $self->_uuid($uuid) : undef;

        if (!$obj) {
            _set_error("The UUID $uuid does not correspond to anything. "
                      . 'Either you accessed a broken link or the object was modified.');
            return $self->_failure;
        }

        if (request->method eq 'POST') {
            my $callback = sub { $self->_uuid($_[1]->uuid, 0) };
            $obj->visit(C101::Visitor->new({
                begin_company    => $callback,
                begin_department => $callback,
                begin_employee   => $callback,
            }));
            remove(sub { $_[0] == $obj }, $self->companies);
            _set_message("Deleted ${\$obj->name}.");
            return $self->_success;
        }

        return $self->_get('delete.tt',
            title  => "Deletion of ${\$obj->name}",
            object => $obj,
            url    => request->uri,
        );
    }


    fun _entries(ArrayRef $list, C101::Model $obj?) {
        my $entries = [];
        for my $pair (@$list) {
            my $key = $pair->[0];
            push($entries => {
                name  => $key,
                label => ucfirst($key),
                value => defined($_ = param($key)) ? $_ : $obj && $obj->$key,
            });
        }
        return entries => $entries;
    }

    fun _messages() {
        my $messages = session('messages');
        session(messages => []);
        return $messages;
    }

    fun _set_message(Str $message) {
        session(messages => []) if not defined session('messages');
        push(session('messages'), {text => $message, is_error => 0});
    }

    fun _set_error(Str $message) {
        session(messages => []) if not defined session('messages');
        push(session('messages'), {text => $message, is_error => 1});
    }

    fun _validate(ArrayRef[Tuple[Str, Str]] $list) {
        my $result = {};
        for my $pair (@$list) {
            my ($key, $type) = @$pair;
            my $value = param($key);
            given ($type) {
                when ('Str') {
                    if ($value =~ /^\s*(.+?)\s*$/) {
                        $result->{$key} = $1 if defined $result;
                    } else {
                        _set_error("Please enter a non-empty $key.");
                        $result = undef;
                    }
                }
                when ('UnsignedNum') {
                    if (looks_like_number($value) && $value >= 0) {
                        $result->{$key} = $value + 0 if defined $result;
                    } else {
                        _set_error("Please enter a non-negative number for $key.");
                        $result = undef;
                    }
                }
                default { die "Don't know how to validate $type" }
            }
        }
        return $result;
    }

}

