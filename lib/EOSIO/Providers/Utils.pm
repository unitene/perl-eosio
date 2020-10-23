package EOSIO::Providers::Utils;
use uni::perl;

use Exporter 'import';
our @EXPORT_OK = qw(cb add_msg_cb);

sub cb {
    my ($fail_callback, $success_callback, $add_message) = (shift, pop, shift);
    return sub {
        my ($r, $message) = (shift, shift);

        unless ($r) {
            $message = "$add_message: $message"
                if $add_message;
            return $fail_callback->(undef, $message, @_);
        }
        $success_callback->($r, $message, @_);
    }
}

sub add_msg_cb {
    my ($add_msg, $cb) = @_;
    sub {
        my ($r, $error_msg) = (shift, shift);
        return $cb->(undef, "$add_msg: $error_msg", @_) unless $r;
        $cb->($r, $error_msg, @_);
    }
}
1;