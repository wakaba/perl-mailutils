package EncodedWord::Encoder;
use strict;
use warnings;
our $VERSION = '1.0';
use MIME::Base64;
use Encode ();

# field-name とかも考慮して、これくらいなら十分だろう的な値
use constant MAX_WORD_LENGTH => 76 - 10;

use constant MAX_LINE_LENGTH => 78; # RFC 5322 2.1.1.

use constant MAX_US_ASCII_ENCODED_WORD_CHARS =>
    int((75 - length '=?US-ASCII?Q??=') / 3);
    # 75: RFC 2047 の制限
    # 3: Q 符号化では =HH で最大3倍になる、一応余裕を見ておく

use constant MAX_UTF_8_ENCODED_WORD_CHARS => 
    int((75 - length '=?UTF-8?B??=') # / 3 * 3
        / 4);
    # 3: UTF-8 では BMP の文字が3バイトで表されるのでたぶんこれでいいだろ的な
    # 3/4: B 符号化では 4/3 倍になる

use constant MAX_SHIFT_JIS_ENCODED_WORD_CHARS => 
    int((75 - length '=?Shift_JIS?B??=') / 2 * 3
        / 4);
    # 2: Shift_JIS では1文字が最大2バイトで表される
    # 3/4: B 符号化では 4/3 倍になる

use constant MAX_ISO_2022_JP_ENCODED_WORD_CHARS =>
    int((75 - length '=?ISO-2022-JP?B??=') * 3 / 4 - 3 * 4);
    # 3/4: B 符号化では 4/3 倍になる
    # 3: エスケープシーケンス1個分のバイト数
    # 4: 何回エスケープが入るかわからないけど、なんとなく4つくらいみておく

# 以上の値で必ずまともな長さになるとは保障できないけど、普通のケースだ
# とたぶんうまくいくはず

my $atext = q[0-9A-Za-z!#$%&'*+/=?^_`{|}~-]; # RFC 5322

my $stext = q[0-9A-Za-z!*+/-]; # RFC 2047 5. (3), except for _ and =

sub encode_structured {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    
    return $class->_encode($_[0], structured => 1, charset => 'utf-8',
                           filter => $args{filter});
}

sub encode_unstructured {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    
    return $class->_encode($_[0], charset => 'utf-8', filter => $args{filter});
}

sub encode_structured_sjis {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    return $class->_encode($_[0], structured => 1, charset => 'shift_jis',
                           perl_encoding => $args{perl_encoding},
                           filter => $args{filter});
}

sub encode_unstructured_sjis {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    return $class->_encode($_[0], charset => 'shift_jis',
                           perl_encoding => $args{perl_encoding},
                           filter => $args{filter});
}

sub encode_structured_jp {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    return $class->_encode($_[0], structured => 1, charset => 'iso-2022-jp',
                           perl_encoding => $args{perl_encoding},
                           filter => $args{filter},
                           no_charset_upgrade => $args{no_charset_upgrade});
}

sub encode_unstructured_jp {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    return $class->_encode($_[0], charset => 'iso-2022-jp',
                           perl_encoding => $args{perl_encoding},
                           filter => $args{filter},
                           no_charset_upgrade => $args{no_charset_upgrade});
}

sub _encode {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];

    my @args = (
        filter => $args{filter},
        perl_encoding => $args{perl_encoding},
        no_charset_upgrade => $args{no_charset_upgrade},
    );
    
    my $line = '';
    my $last_line_length = 0;

    my $append_word = sub {
        if (($last_line_length + 1 + length $_[0]) < MAX_LINE_LENGTH) {
            $line .= ' ' . $_[0];
            $last_line_length += 1 + length $_[0];
        } else {
            # RFC 解釈の問題から一応スペースは2個にしておくお (意味ないかな?)
            $line .= "\x0D\x0A  " . $_[0];
            $last_line_length = 2 + length $_[0];
        }
    };

    my $prev_was_encoded_word = 0;
    for my $word (split /[\x09\x0A\x0D\x20]/, $_[0]) { # RFC 5322 FWS
        next unless length $word;
        if ($word =~ /[^\x00-\x7F]/) { # Contains Non-ASCII characters
            $word = ' ' . $word if $prev_was_encoded_word;
            if ($args{charset} eq 'iso-2022-jp') {
                my @word = $class->_iso_2022_jp_encoded_words($word, @args);
                $append_word->($_) for @word;
            } elsif ($args{charset} eq 'shift_jis') {
                my @word = $class->_shift_jis_encoded_words($word, @args);
                $append_word->($_) for @word;
            } else {
                my @word = $class->_utf_8_encoded_words($word, @args);
                $append_word->($_) for @word;
            }
            $prev_was_encoded_word = 1;
        } elsif ((length $word > MAX_WORD_LENGTH) or # Too long
                 ($args{structured} and # Contains special characters
                  $word =~ /[^$atext]/o) or
                 $word =~ /^=\?/) {
            $word = ' ' . $word if $prev_was_encoded_word;
            if ($args{charset} eq 'iso-2022-jp') {
                # ISO-2022-JP にしか対応していない古い MUA は ASCII
                # encoded-word にも対応していなそう
                my @word = $class->_iso_2022_jp_encoded_words($word, @args);
                $append_word->($_) for @word;
            } elsif ($args{charset} eq 'shift_jis') {
                # シフトJISにしか対応していない適当な MUA は ASCII
                # encoded-word にも対応していなそう
                my @word = $class->_shift_jis_encoded_words($word,
                    perl_encoding => $args{perl_encoding},
                    @args,
                );
                $append_word->($_) for @word;
            } else {
                my @word = $class->_us_ascii_encoded_words($word, @args);
                $append_word->($_) for @word;
            }
            $prev_was_encoded_word = 1;
        } else {
            $append_word->(Encode::encode 'us-ascii', $word);
            $prev_was_encoded_word = 0;
        }
    }

    $line =~ s/^ //;
    
    return $line;
}

sub _us_ascii_encoded_words {
    my $class = shift;
    # string $_[0]

    my @r;
    
    pos($_[0]) = 0;
    while (pos $_[0] < length $_[0]) {
        # substr で utf8 フラグが落ちる (はず)
        my $s = substr $_[0], pos($_[0]), MAX_US_ASCII_ENCODED_WORD_CHARS;
        pos($_[0]) += length $s;
        $s =~ s/([^$stext])/sprintf '=%02X', ord $1/geo;
        push @r, '=?US-ASCII?Q?' . $s . '?=';
    }

    return @r;
}

sub _utf_8_encoded_words {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];

    my @r;
    
    pos($_[0]) = 0;
    while (pos $_[0] < length $_[0]) {
        my $s = substr $_[0], pos($_[0]), MAX_UTF_8_ENCODED_WORD_CHARS;
        pos($_[0]) += length $s;
        $s = $args{filter}->($s);
        $s = encode_base64 Encode::encode 'utf-8', $s;
        $s =~ s/\s+//g;
        push @r, '=?UTF-8?B?' . $s . '?=';
    }

    return @r;
}

use constant SJIS_GETA => Encode::encode 'shift_jis', "\x{3013}";

sub _shift_jis_encoded_words {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    my $encoding = $args{perl_encoding} || 'shift_jis';
    my @r;
    
    pos($_[0]) = 0;
    while (pos $_[0] < length $_[0]) {
        my $s = substr $_[0], pos($_[0]), MAX_SHIFT_JIS_ENCODED_WORD_CHARS;
        pos($_[0]) += length $s;
        $s = $args{filter}->($s);
        $s = encode_base64 Encode::encode $encoding, $s, sub { SJIS_GETA };
        $s =~ s/\s+//g;
        push @r, '=?Shift_JIS?B?' . $s . '?=';
    }

    return @r;
}

sub _iso_2022_jp_encoded_words {
    my $class = shift;
    # string $_[0]
    my %args = @_[1..$#_];
    my $encoding = $args{perl_encoding} || 'iso-2022-jp';

    my @r;
    
    pos($_[0]) = 0;
    while (pos $_[0] < length $_[0]) {
        my $s = substr $_[0], pos($_[0]), MAX_ISO_2022_JP_ENCODED_WORD_CHARS;
        pos($_[0]) += length $s;
        $s = $args{filter}->($s);
        eval {
            my $s = encode_base64
                Encode::encode $encoding, $s, Encode::FB_CROAK;
            $s =~ s/\s+//g;
            push @r, '=?ISO-2022-JP?B?' . $s . '?=';
            1;
        } or do {
            if ($args{no_charset_upgrade}) {
                my $s = encode_base64 Encode::encode $encoding, $s;
                $s =~ s/\s+//g;
                push @r, '=?ISO-2022-JP?B?' . $s . '?=';
            } else {
                push @r, $class->_utf_8_encoded_words($s, %args);
            }
        };
    }

    return @r;
}

=pod

既知の問題点

  - 長さにかなり余裕を見ているのでかなり短めの encoded-word を乱発する
  - 分割の仕方の都合上、 UTF-8 ででてきた encoded-words のいくつかは実は
    ASCII で十分だったりする (ISO-2022-JP でも同様)

見た目的にちょっとみっともないだけで大して実害はない

=cut

1;
