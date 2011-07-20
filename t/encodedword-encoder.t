package test::EncodedWord::Encoder;
use strict;
use warnings;
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use base qw(Test::Class);
use Test::More;
use EncodedWord::Encoder;
use Encode;
require utf8;

sub _encode : Test(216) {
    use utf8;
    for my $data (
        {
            input => 'This is a pen',
            unstructured => 'This is a pen',
            structured => 'This is a pen',
            unstructured_jp => 'This is a pen',
            structured_jp => 'This is a pen',
            unstructured_sjis => 'This is a pen',
            structured_sjis => 'This is a pen',
        },
        {
            input => 'This is a pen.',
            unstructured => 'This is a pen.',
            structured => 'This is a =?US-ASCII?Q?pen=2E?=',
            unstructured_jp => 'This is a pen.',
            structured_jp => 'This is a =?ISO-2022-JP?B?cGVuLg==?=',
            unstructured_sjis => 'This is a pen.',
            structured_sjis => 'This is a =?Shift_JIS?B?cGVuLg==?=',
        },
        {
            input => 'ThisisalonglongsentenseThisisalonglongsentenseThisisalonglongsentenseThisisalonglongsentense',
            unstructured => "=?US-ASCII?Q?Thisisalonglongsente?= =?US-ASCII?Q?nseThisisalonglongse?=\x0D\x0A  =?US-ASCII?Q?ntenseThisisalonglon?= =?US-ASCII?Q?gsentenseThisisalong?=\x0D\x0A  =?US-ASCII?Q?longsentense?=",
            structured => "=?US-ASCII?Q?Thisisalonglongsente?= =?US-ASCII?Q?nseThisisalonglongse?=\x0D\x0A  =?US-ASCII?Q?ntenseThisisalonglon?= =?US-ASCII?Q?gsentenseThisisalong?=\x0D\x0A  =?US-ASCII?Q?longsentense?=",
            unstructured_jp => "=?ISO-2022-JP?B?VGhpc2lzYWxvbmdsb25nc2VudGVuc2VUaGlzaXNh?=\x0D\x0A  =?ISO-2022-JP?B?bG9uZ2xvbmdzZW50ZW5zZVRoaXNpc2Fsb25nbG9u?=\x0D\x0A  =?ISO-2022-JP?B?Z3NlbnRlbnNlVGhpc2lzYWxvbmdsb25nc2VudGVu?=\x0D\x0A  =?ISO-2022-JP?B?c2U=?=",
            structured_jp => "=?ISO-2022-JP?B?VGhpc2lzYWxvbmdsb25nc2VudGVuc2VUaGlzaXNh?=\x0D\x0A  =?ISO-2022-JP?B?bG9uZ2xvbmdzZW50ZW5zZVRoaXNpc2Fsb25nbG9u?=\x0D\x0A  =?ISO-2022-JP?B?Z3NlbnRlbnNlVGhpc2lzYWxvbmdsb25nc2VudGVu?=\x0D\x0A  =?ISO-2022-JP?B?c2U=?=",
            unstructured_sjis => "=?Shift_JIS?B?VGhpc2lzYWxvbmdsb25nc2VudGVucw==?=\x0D\x0A  =?Shift_JIS?B?ZVRoaXNpc2Fsb25nbG9uZ3NlbnRlbg==?=\x0D\x0A  =?Shift_JIS?B?c2VUaGlzaXNhbG9uZ2xvbmdzZW50ZQ==?=\x0D\x0A  =?Shift_JIS?B?bnNlVGhpc2lzYWxvbmdsb25nc2VudA==?= =?Shift_JIS?B?ZW5zZQ==?=",
            structured_sjis => "=?Shift_JIS?B?VGhpc2lzYWxvbmdsb25nc2VudGVucw==?=\x0D\x0A  =?Shift_JIS?B?ZVRoaXNpc2Fsb25nbG9uZ3NlbnRlbg==?=\x0D\x0A  =?Shift_JIS?B?c2VUaGlzaXNhbG9uZ2xvbmdzZW50ZQ==?=\x0D\x0A  =?Shift_JIS?B?bnNlVGhpc2lzYWxvbmdsb25nc2VudA==?= =?Shift_JIS?B?ZW5zZQ==?=",
        },
        {
            input => 'こんにちは、みなさん',
            unstructured => '=?UTF-8?B?44GT44KT44Gr44Gh44Gv44CB44G/44Gq44GV44KT?=',
            structured => '=?UTF-8?B?44GT44KT44Gr44Gh44Gv44CB44G/44Gq44GV44KT?=',
            unstructured_jp => '=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTyEiJF8kSiQ1JHMbKEI=?=',
            structured_jp => '=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTyEiJF8kSiQ1JHMbKEI=?=',
            unstructured_sjis => '=?Shift_JIS?B?grGC8YLJgr+CzYFBgt2CyIKzgvE=?=',
            structured_sjis => '=?Shift_JIS?B?grGC8YLJgr+CzYFBgt2CyIKzgvE=?=',
        },
        {
            input => 'こんにちは、id:wakabatanさん',
            unstructured => '=?UTF-8?B?44GT44KT44Gr44Gh44Gv44CBaWQ6d2FrYWJh?= =?UTF-8?B?dGFu44GV44KT?=',
            structured => '=?UTF-8?B?44GT44KT44Gr44Gh44Gv44CBaWQ6d2FrYWJh?= =?UTF-8?B?dGFu44GV44KT?=',
            unstructured_jp => '=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTyEiGyhCaWQ6d2FrYWJhdGFuGyRCJDUkcxsoQg==?=',
            structured_jp => '=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTyEiGyhCaWQ6d2FrYWJhdGFuGyRCJDUkcxsoQg==?=',
            unstructured_sjis => '=?Shift_JIS?B?grGC8YLJgr+CzYFBaWQ6d2FrYWJhdGFugrOC8Q==?=',
            structured_sjis => '=?Shift_JIS?B?grGC8YLJgr+CzYFBaWQ6d2FrYWJhdGFugrOC8Q==?=',
        },
        {
            input => 'こんにちは、 id:wakabatan さん',
            unstructured => "=?UTF-8?B?44GT44KT44Gr44Gh44Gv44CB?= id:wakabatan =?UTF-8?B?44GV44KT?=",
            structured => "=?UTF-8?B?44GT44KT44Gr44Gh44Gv44CB?= =?US-ASCII?Q?=20id=3Awakabatan?=\x0D\x0A  =?UTF-8?B?IOOBleOCkw==?=",
            unstructured_jp => "=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTyEiGyhC?= id:wakabatan\x0D\x0A  =?ISO-2022-JP?B?GyRCJDUkcxsoQg==?=",
            structured_jp => "=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTyEiGyhC?=\x0D\x0A  =?ISO-2022-JP?B?IGlkOndha2FiYXRhbg==?= =?ISO-2022-JP?B?IBskQiQ1JHMbKEI=?=",
            unstructured_sjis => "=?Shift_JIS?B?grGC8YLJgr+CzYFB?= id:wakabatan =?Shift_JIS?B?grOC8Q==?=",
            structured_sjis => "=?Shift_JIS?B?grGC8YLJgr+CzYFB?= =?Shift_JIS?B?IGlkOndha2FiYXRhbg==?=\x0D\x0A  =?Shift_JIS?B?IIKzgvE=?=",
        },
        {
            input => '[10 月 18 日の wakabatan さんの★レポート]',
            unstructured => "[10 =?UTF-8?B?5pyI?= 18 =?UTF-8?B?5pel44Gu?= wakabatan\x0D\x0A  =?UTF-8?B?44GV44KT44Gu4piF44Os44Od44O844OIXQ==?=",
            structured => "=?US-ASCII?Q?=5B10?= =?UTF-8?B?IOaciA==?= 18 =?UTF-8?B?5pel44Gu?= wakabatan\x0D\x0A  =?UTF-8?B?44GV44KT44Gu4piF44Os44Od44O844OIXQ==?=",
            unstructured_jp => "[10 =?ISO-2022-JP?B?GyRCN24bKEI=?= 18 =?ISO-2022-JP?B?GyRCRnwkThsoQg==?=\x0D\x0A  wakabatan =?ISO-2022-JP?B?GyRCJDUkcyROIXolbCVdITwlSBsoQl0=?=",
            structured_jp => "=?ISO-2022-JP?B?WzEw?= =?ISO-2022-JP?B?IBskQjduGyhC?= 18\x0D\x0A  =?ISO-2022-JP?B?GyRCRnwkThsoQg==?= wakabatan\x0D\x0A  =?ISO-2022-JP?B?GyRCJDUkcyROIXolbCVdITwlSBsoQl0=?=",
            unstructured_sjis => "[10 =?Shift_JIS?B?jI4=?= 18 =?Shift_JIS?B?k/qCzA==?= wakabatan\x0D\x0A  =?Shift_JIS?B?grOC8YLMgZqDjIN8gVuDZ10=?=",
            structured_sjis => "=?Shift_JIS?B?WzEw?= =?Shift_JIS?B?IIyO?= 18 =?Shift_JIS?B?k/qCzA==?=\x0D\x0A  wakabatan =?Shift_JIS?B?grOC8YLMgZqDjIN8gVuDZ10=?=",
        },
        {
            input => 'ISO-2022-JP で表せない文字' . qq{\x{2001}},
            unstructured => 'ISO-2022-JP =?UTF-8?B?44Gn6KGo44Gb44Gq44GE5paH5a2X4oCB?=',
            structured => 'ISO-2022-JP =?UTF-8?B?44Gn6KGo44Gb44Gq44GE5paH5a2X4oCB?=',
            unstructured_jp => 'ISO-2022-JP =?UTF-8?B?44Gn6KGo44Gb44Gq44GE5paH5a2X4oCB?=',
            structured_jp => 'ISO-2022-JP =?UTF-8?B?44Gn6KGo44Gb44Gq44GE5paH5a2X4oCB?=',
            unstructured_sjis => "ISO-2022-JP =?Shift_JIS?B?gsWVXIK5gsiCopW2jpqBrA==?=",
            structured_sjis => "ISO-2022-JP =?Shift_JIS?B?gsWVXIK5gsiCopW2jpqBrA==?=",
            roundtrip_sjis => "ISO-2022-JPで表せない文字〓",
        },
        {
            input => 'Wakaba <wakabatan@hatena.ne.jp>',
            unstructured => 'Wakaba <wakabatan@hatena.ne.jp>',
            structured => 'Wakaba =?US-ASCII?Q?=3Cwakabatan=40hatena=2Ene?= =?US-ASCII?Q?=2Ejp=3E?=',
            unstructured_jp => 'Wakaba <wakabatan@hatena.ne.jp>',
            structured_jp => 'Wakaba =?ISO-2022-JP?B?PHdha2FiYXRhbkBoYXRlbmEubmUuanA+?=',
            unstructured_sjis => 'Wakaba <wakabatan@hatena.ne.jp>',
            structured_sjis => 'Wakaba =?Shift_JIS?B?PHdha2FiYXRhbkBoYXRlbmEubmUuag==?= =?Shift_JIS?B?cD4=?=',
        },
        {
            input => 'Re: =?US-ASCII?Q?abc?=',
            unstructured => 'Re: =?US-ASCII?Q?=3D=3FUS-ASCII=3FQ=3Fabc=3F=3D?=',
            structured => '=?US-ASCII?Q?Re=3A?= =?US-ASCII?Q?=20=3D=3FUS-ASCII=3FQ=3Fabc=3F=3D?=',
            unstructured_jp => 'Re: =?ISO-2022-JP?B?PT9VUy1BU0NJST9RP2FiYz89?=',
            structured_jp => '=?ISO-2022-JP?B?UmU6?= =?ISO-2022-JP?B?ID0/VVMtQVNDSUk/UT9hYmM/PQ==?=',
            unstructured_sjis => 'Re: =?Shift_JIS?B?PT9VUy1BU0NJST9RP2FiYz89?=',
            structured_sjis => '=?Shift_JIS?B?UmU6?= =?Shift_JIS?B?ID0/VVMtQVNDSUk/UT9hYmM/PQ==?=',
        },
        {
            input => '',
            unstructured => '',
            structured => '',
            unstructured_jp => '',
            structured_jp => '',
            unstructured_sjis => '',
            structured_sjis => '',
        },
        {
            input => (Encode::decode 'us-ascii', 'ab.c'),
            unstructured => 'ab.c',
            structured => '=?US-ASCII?Q?ab=2Ec?=',
            unstructured_jp => 'ab.c',
            structured_jp => '=?ISO-2022-JP?B?YWIuYw==?=',
            unstructured_sjis => 'ab.c',
            structured_sjis => '=?Shift_JIS?B?YWIuYw==?=',
        },
    ) {
        for my $type (qw/
            unstructured structured
            unstructured_jp structured_jp
            unstructured_sjis structured_sjis
        /) {
            my $method = 'encode_' . $type;
            my $result = EncodedWord::Encoder->$method($data->{input}, filter => sub { $_[0] });
            is $result, $data->{$type};
            ok !utf8::is_utf8($result);

            my $decoded = decode 'MIME-Header', $result;
            my $in = $type =~ /sjis/ ? $data->{roundtrip_sjis} || $data->{input} : $data->{input};
            $in =~ tr/ //d; # Encode::MIME::Header はまともにスペースを扱えない
            $decoded =~ tr/ //d;
            is $decoded, $in;
        }
    }
}

__PACKAGE__->runtests;

1;
