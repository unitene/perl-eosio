package EOSIO::Utils;
use uni::perl;
use Data::Dumper;
use Encode;
use Mojo::JSON;

use base 'Exporter';
our @EXPORT = qw(cb utf8ToHex decode_json encode_json);

use constant {
    MAX_NAME_IDX => 12,
};

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

sub utf8ToHex {
    my ($str) = @_;
    unpack "H*" => encode_utf8($str);
}

sub encode_json {
    Mojo::JSON::encode_json(@_);
}

sub decode_json {
    Mojo::JSON::decode_json(@_);
}

sub json_true {
    Mojo::JSON::true;
}

sub json_false {
    Mojo::JSON::false;
}

sub name_to_long {
    my $name_str = shift;

    my $char_to_symbol = sub {
        return 0 unless $_[0];
        my $c = ord(shift);
        if ($c >= ord('a') and $c <= ord('z')) {
            return $c - ord('a') + 6;
        }
        if ($c >= ord('1') && $c <= ord('5')) {
            return $c - ord('1') + 1;
        }
        return 0;
    };

    my @a = split '' => $name_str;
    my $v = Math::BigInt->new();
    for (my $i = 0; $i <= MAX_NAME_IDX; $i++) {
        my $c = Math::BigInt->new($char_to_symbol->(shift @a));
        $i < MAX_NAME_IDX ?
            $c->band(0x1f)->blsft(64 - 5 * ($i +1))
            : $c->band(0x0f);
        $v->bior($c);
    }
    return $v;
}


1;