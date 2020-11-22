package EOSIO::Utils;
use uni::perl;
use Data::Dumper;
use Encode;
use Mojo::JSON;
use Math::BigInt;

use base 'Exporter';
our @EXPORT = qw(cb utf8ToHex decode_json encode_json name_to_long long_to_name gen_name);

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
            $c->band(0x1f)->blsft(64 - 5 * ($i + 1))
            : $c->band(0x0f);
        $v->bior($c);
    }
    return $v;
}

sub long_to_name {
    my $val = shift;
    $val = Math::BigInt->new($val) unless ref $val;

    my $symbol_to_char = sub {
        return '' unless $_[0];
        my $c = shift;
        if ($c >= 1 && $c <= 5) {
            return chr(ord('1') + $c - 1);
        }
        elsif ($c >= 6 && $c <= 31) {
            return chr(ord('a') + $c - 6);
        }
        return '';
    };

    my @out;
    for (my $i = 0; $i <= MAX_NAME_IDX; $i++) {
        my $tmp = $val->copy;
        if ($i == 0) {
            $tmp->band(0x0f);
            $val->brsft(4);
        }
        else {
            $tmp->band(0x1f);
            $val->brsft(5);
        }
        push @out => $symbol_to_char->($tmp->numify());
    }

    return join "" => reverse @out;
}

sub gen_name {
    my @Alpha = (
        [ 'a' .. 'z' ],
        [ 'a' .. 'z', '1' .. '5' ],
        [ 'a' .. 'z', '1' .. '5', '.' ],
    );

    join '' => map {
        my @c_alpha;
        if ($_ == 1) {
            $Alpha[0]->[rand scalar(@{$Alpha[0]})]
        }
        elsif ($_ == 12) {
            $Alpha[1]->[rand scalar(@{$Alpha[1]})]
        }
        else {
            $Alpha[2]->[rand scalar(@{$Alpha[2]})]
        }
    } (1 .. 12);
}

1;