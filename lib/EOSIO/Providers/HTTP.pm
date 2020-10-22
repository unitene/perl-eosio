package EOSIO::Providers::HTTP;
use uni::perl;
use Data::Dumper;
use Mojo::JSON 'decode_json';
use Mojo::UserAgent;

use Moo;

has 'url' => (is => 'rw', required => 1);
has 'max_request_retry' => (is => 'rw', default => 1);
has 'ua' => (
    is      => 'rw',
    default => sub {
        my $ua = Mojo::UserAgent->new;
        $ua->inactivity_timeout(60);
        $ua;
    }
);

sub post_request {
    shift->make_request(@_);
}

sub make_request {
    my ($self, $path, $cb) = (shift, shift, pop);
    my ($params, $try_cnt) = (shift, shift);
    $params //= {};
    $self->_request($path, $params, sub {
        my (undef, $tx) = @_;
        my $result = decode_json($tx->result->body);
        if (my $error = $tx->error) {
            unless ($error->{code}) {
                if ($self->_error_handler($tx, ++$try_cnt, $cb)) {
                    my $t;
                    $t = EV::timer $self->retry_timeout, 0, sub {
                        undef $t;
                        $self->make_request($params, $try_cnt, $cb);
                    };
                }
            }
            else {
                $result->{error}->{details}->[0]->{message} ?
                    $cb->(undef, $result->{error}->{details}->[0]->{message})
                    : $cb->(undef, "Error: $error->{message}, code - " . $error->{code}, $error->{message});
            }
        }
        else {
            if ($result->{error}) {
                $cb->(undef, $result->{error}->{code} . ': ' . $result->{error}->{message});
            }
            else {
                return $cb->($result, 'OK');
            }
        }
    });
}

sub _request {
    my ($self, $path, $params, $cb) = @_;
    $self->ua->post($self->url . $path, json => $params, $cb);
}

sub _error_handler {
    my ($self, $tx, $try_cnt, $cb) = @_;

    if ($try_cnt < $self->max_request_retry) {
        return 1;
    }
    else {
        my $err = $tx->error;
        my $error_msg = "$err->{message}: " . $tx->res->body;
        $cb->(undef, $error_msg);
        return undef;
    }

}

1;