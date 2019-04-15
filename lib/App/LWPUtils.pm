package App::LWPUtils;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Util qw(gen_modified_sub);

our %SPEC;

sub _lwputil_request {
    require HTTP::Request;

    my ($class, %args) = @_;

    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;

    my $res;
    my $method = $args{method} // 'GET';
    for my $i (0 .. $#{ $args{urls} }) {
        my $url = $args{urls}[$i];
        my $is_last_url = $i == $#{ $args{urls} };

        my $req = HTTP::Request->new($method => $url);

        if (defined $args{headers}) {
            for (keys %{ $args{headers} }) {
                $req->header($_ => $args{headers}{$_});
            }
        }
        if (defined $args{content}) {
            $req->content($opts{content});
        } elsif (!(-t STDIN)) {
            local $/;
            $req->content(scalar <STDIN>);
        }

        my $res0 = $class->new(%{ $args{attributes} // {} })
            ->request($req);
        my $success = $res0->is_success;

        if ($args{raw}) {
            $res = [200, "OK", $res0->as_string];
        } else {
            $res = [$res0->code, $res0->message, $res0->content];
            print $res0->content unless $is_last_url;
        }

        unless ($success) {
            last unless $args{ignore_errors};
        }
    }
    $res;
}

$SPEC{lwputil_request} = {
    v => 1.1,
    summary => 'Perform request(s) with LWP::UserAgent',
    args => {
        urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        method => {
            schema => ['str*', match=>qr/\A[A-Z]+\z/],
            default => 'GET',
            cmdline_aliases => {
                delete => {summary => 'Shortcut for --method DELETE', is_flag=>1, code=>sub { $_[0]{method} = 'DELETE' } },
                get    => {summary => 'Shortcut for --method GET'   , is_flag=>1, code=>sub { $_[0]{method} = 'GET'    } },
                head   => {summary => 'Shortcut for --method HEAD'  , is_flag=>1, code=>sub { $_[0]{method} = 'HEAD'   } },
                post   => {summary => 'Shortcut for --method POST'  , is_flag=>1, code=>sub { $_[0]{method} = 'POST'   } },
                put    => {summary => 'Shortcut for --method PUT'   , is_flag=>1, code=>sub { $_[0]{method} = 'PUT'    } },
            },
        },
        attributes => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'attribute',
            summary => 'Pass attributes to LWP::UserAgent constructor',
            schema => ['hash*', each_key => 'str*'],
        },
        headers => {
            schema => ['hash*', of=>'str*'],
            'x.name.is_plural' => 1,
            'x.name.singular' => 'header',
        },
        content => {
            schema => 'str*',
        },
        raw => {
            schema => 'bool*',
        },
        ignore_errors => {
            summary => 'Ignore errors',
            description => <<'_',

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With `ignore_errors` set to true, will just log the error
and continue. Will return with the last error response.

_
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
        },
        # XXX option: agent
        # XXX option: timeout
        # XXX option: post form
    },
};
sub http_tiny {
    _lwputil_request('LWP::UserAgent', @_);
}

gen_modified_sub(
    output_name => 'lwputil_request_plugin',
    base_name   => 'lwputil_request',
    summary => 'Perform request(s) with LWP::UserAgent::Plugin',
    description => <<'_',

Like `lwputil_request`, but uses <pm:LWP::UserAgent::Plugin> instead of
<pm:LWP::UserAgent>. See the documentation of LWP::UserAgent::Plugin for more
details.

_
    output_code => sub { _lwputil_request('LWP::UserAgent::Plugin', @_) },
);

1;
# ABSTRACT: Command-line utilities related to LWP

=head1 SYNOPSIS


=head1 DESCRIPTION

This distribution includes several utilities related to L<LWP> and
L<LWP::UserAgent>:

#INSERT_EXECS_LIST


=head1 SEE ALSO

Standard utilities that come with L<LWP>: L<lwp-download>, L<lwp-request>,
L<lwp-dump>, L<lwp-mirror>.
