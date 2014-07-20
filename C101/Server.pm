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

    method BUILD        { $self->_uuids(uuids(@{$self->companies}))               }

    method get(Str $id) { $id eq 'root' ? $self->companies : $self->_uuids->{$id} }

    method save()       { serialize($self->companies, 'companies.bin')            }

    method remove(C101::Model $obj) {
        delete $self->_uuids->{$obj->uuid};
        remove(sub { $_[0] == $obj }, $self->companies);
    }


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

    method _info {
        if (request->is_ajax) {
            $self->_jsonify(
                messages => _messages(),
                type     => 'info',
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


    method handle_index() {
        return $self->_get('index.tt',
            title     => 'Contribution:Dancer',
            companies => $self->companies,
        );
    };

    method handle_add(Str :$type, Str :$list, ArrayRef[Tuple[Str, Str]] :$validate) {
        my $uuid   = param('uuid');
        my $parent = $uuid ? $self->_uuid($uuid) : undef;

        if ($list && !$parent) {
            _set_error("The UUID $uuid does not correspond to anything. Either you "
                     . 'accessed a broken link or the object was modified.');
            return $self->_failure;
        }

        if (request->method eq 'POST') {
            my $valid = _validate($validate);
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
            _entries($validate),
        );
    }

    method handle_edit(Str :$title, Str :$type, ArrayRef[Tuple[Str, Str]] :$validate) {
        my $uuid = param('uuid');
        my $obj  = $uuid ? $self->_uuid($uuid) : undef;

        if (!$obj || !$obj->isa("C101::$type")) {
            _set_error("The UUID $uuid does not correspond to any $type. "
                      . 'Either you accessed a broken link or the object was modified.');
            return $self->_failure;
        }

        if (request->method eq 'POST') {
            my $valid = _validate($validate);
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
            title => sprintf($title, $obj->name),
            url   => request->uri,
            _entries($validate, $obj),
        );
    }

    method handle_delete() {
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

    method handle_operation(CodeRef :$op, Str :$message, Bool :$mutate = 0) {
        my $uuid = param('uuid');
        my $obj  = $uuid ? $self->_uuid($uuid) : undef;

        if (!$obj) {
            _set_error("The UUID $uuid does not correspond to anything. "
                      . 'Either you accessed a broken link or the object was modified.');
            return $self->_failure;
        }

        my $result = &$op($obj);
        _set_message(sprintf($message, $obj->name, $result));
        return $mutate ? $self->_success : $self->_info;
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

__END__

=head2 C101::Server

A class for a bunch of helper operations for the Web UI feature. No parameters are
needed for construction.

Has a companies array reference that is deserialized from the file I<companies.bin> upon
construction. There is also a hash of UUIDs mapping to their respective objects, but
that's private.

=head3 method save()

Serializes the companies into the file I<companies.bin>. Returns nothing interesting.

=head3 method handle_index()

Handles a request for the main page and returns the response.

=head3 method handle_add(Str :$type, Str :$list, ArrayRef[Tuple[Str, Str]] :$validate)

Handle a GET, POST or AJAX request to add a new object to the tree. The $type is either
C<'Company'>, C<'Department'> or C<'Employee'>. $list is the name of the list in the
parent item. $validate contains a list of pairs. Each pair has the name of a parameter
and the type of that parameter, which is either C<'Str'> or C<'UnsignedNum'>.

This will check if the given C<param('uuid')> corresponds to a valid object, then
validate the form parameters according to $validate and finally create the new object.
The client is informed about success or failure.

=head3 method handle_edit(Str :$title, Str :$type, ArrayRef[Tuple[Str, Str]] :$validate)

Like handle_add, but for editing. Instead of a $list there is a $title that should be
ready to be I<sprintf>ed to with the name of the object being edited. For example,
C<'Edit Employee %s'>.

=head3 method handle_delete()

Handles a GET, POST or AJAX request for deleting an object.

Checks if C<param('uuid')> corresponds to a valid object and then deletes that object and
all its children from the tree and the hash of UUIDs.

=cut

