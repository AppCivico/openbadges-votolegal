use strict;

use utf8;
use JSON;
use File::stat;
use Time::localtime;
use HTML::TreeBuilder::XPath;
use Text::Unaccent::PurePerl qw/unac_string/;
use File::Slurp;
use File::Path qw(remove_tree);
use Text::CSV::Hashify;

sub trim($) { my $t = shift; $t =~ s/\s+$//; $t =~ s/^\s+//; $t; }

my $org = {

    "name"  => "RAPS",
    "image" => "https://raw.githubusercontent.com/AppCivico/openbadges-rnsp/master/logo-aplicacao-branco-RAPS.jpg",
    "url"   => "https://www.raps.org.br/",
    "email" => 'comunicacao@raps.org.br',

};
# isso aqui que eu acho que ta errado.. se a org é RAPS, isso nao deveria ser badges.votolegal
my $base = 'http://badges-raps.votolegal.org.br';

my $badge_raps = {

    "name" => "RAPS (Rede de Ação Política pela Sustentabilidade)",
    "description" =>
"A Rede de Ação Política pela Sustentabilidade – RAPS objetiva contribuir para o fortalecimento e o aperfeiçoamento da democracia e das instituições republicanas mediante o apoio à formação de lideranças políticas que colaborem com a transformação do Brasil em um país mais justo, próspero, solidário, democrático e sustentável.",
    "image"    => "https://raw.githubusercontent.com/AppCivico/openbadges-rnsp/master/logo-aplicacao-branco-RAPS.jpg",
    "criteria" => "https://www.raps.org.br/lider-raps/",
    "criteria:2" => "https://www.raps.org.br/jovem-raps/",
    "criteria:3" => "https://www.raps.org.br/empreendedor-civico/",

    "tags"     => ["RAPS"],
    "issuer"   => "$base/organization.json"
};

my $hash_ref = hashify('raps.csv', 'nome');


use Encode qw/ decode/;
my @pref;
foreach my $prefn (keys %$hash_ref) {
    my $pref = $hash_ref->{$prefn};

    my $cidade   = decode( 'utf-8', trim $pref->{cidade} );

    my $estado   = decode( 'utf-8', trim $pref->{estado} );
    my $prefeito = decode( 'utf-8', trim $pref->{nome} );
    my $partido  = decode( 'utf-8', trim $pref->{partido} );

    my $uid = lc( unac_string "$estado-$cidade" );
    $uid =~ s/ /-/g;

    my $badge = {
        "uid"       => $uid,
        "recipient" => {
            "type"     => "email",
            "hashed"   => JSON::false,
            "identity" => trim $pref->{email}
        },
        "image"                  => "https://raw.githubusercontent.com/AppCivico/openbadges-rnsp/master/logo-aplicacao-branco-RAPS.jpg",
        "evidence"               => trim $pref->{perfil},
        "issuedOn"               => time,
        "nossasaopaulo:partido"  => $partido,
        "nossasaopaulo:prefeito" => $prefeito,
        "nossasaopaulo:estado"   => $estado,
        "nossasaopaulo:cidade"   => $cidade,
        "badge"                  => "$base/raps.json",
        "verify"                 => {
            "type" => "hosted",
            "url"  => "$base/badges/$uid.json"
        }
    };
    push @pref, $badge;

}

if ( @pref > 10 ) {

    remove_tree "openbadges";

    mkdir "openbadges";
    mkdir "openbadges/badges";

    write_file( "openbadges/organization.json", { binmode => ':raw' }, to_json( $org, { utf8 => 1, pretty => 1 } ) );
    write_file( "openbadges/raps.json", { binmode => ':raw' }, to_json( $badge_raps, { utf8 => 1, pretty => 1 } ) );

    write_file(
        "openbadges/badges/" . $_->{uid} . '.json',
        { binmode => ':raw' },
        to_json( $_, { utf8 => 1, pretty => 1 } )
    ) for @pref;

    write_file(
        "openbadges/collections.json",
        { binmode => ':raw' },
        to_json( { badges => [ map { +{ url => $_->{verify}{url} } } @pref ] }, { utf8 => 1, pretty => 1 } )
    );

}
