use strict;

use utf8;
use JSON;
use File::stat;
use Time::localtime;
use HTML::TreeBuilder::XPath;
use Text::Unaccent::PurePerl qw/unac_string/;
use File::Slurp;
use File::Path qw(remove_tree);

sub trim($) { my $t = shift; $t =~ s/\s+$//; $t =~ s/^\s+//; $t; }
if ( !-e 'candidatos.html' || time - ( stat('candidatos.html')->mtime ) > 86400 ) {
    `curl http://cidadessustentaveis.org.br/signatarios-candidatos/ > candidatos.html`;
}

my $org = {

    "name"  => "Movimento Nossa São Paulo",
    "image" => "http://www.nossasaopaulo.org.br/sites/default/files/logo_drupal.png",
    "url"   => "http://www.nossasaopaulo.org.br/",
    "email" => 'faleconosco@isps.org.br'
};
my $base = 'http://badges.nossasaopaulo.org.br';

my $badge_pcs = {

    "name" => "Programa Cidades Sustentáveis",
    "description" =>
"Uma realização da Rede Nossa São Paulo, da Rede Social Brasileira por Cidades Justas e Sustentáveis e do Instituto Ethos, o programa oferece uma plataforma que funciona como uma agenda para a sustentabilidade, incorporando de maneira integrada as dimensões social, ambiental, econômica, política e cultural e abordando as diferentes áreas da gestão pública em 12 eixos temáticos. A cada um deles estão associados indicadores, casos exemplares e referências nacionais e internacionais de excelência. Estamos diante da oportunidade de criar um novo padrão de relação dos cidadãos com a política, os candidatos assumindo compromissos concretos e os cidadãos acompanhando os resultados desses compromissos.",
    "image"    => "http://cidadessustentaveis.org.br/sites/default/files/logo.png",
    "criteria" => "http://cidadessustentaveis.org.br/institucional/oprograma",
    "tags"     => ["Cidades Sustentáveis"],
    "issuer"   => "$base/organization.json"
};

my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse_file("candidatos.html");

my @nodes = $tree->findnodes(
    q{//*[@id='datatable-1']/tbody/tr}    # just a string, not a string containings quotes
);

use Encode qw/ decode/;
my @pref;
foreach my $pref (@nodes) {

    my $cidade   = decode( 'utf-8', trim $pref->findvalue('td[1]') );
    my $estado   = decode( 'utf-8', trim $pref->findvalue('td[2]') );
    my $prefeito = decode( 'utf-8', trim $pref->findvalue('td[3]') );
    my $partido  = decode( 'utf-8', trim $pref->findvalue('td[4]') );

    my $uid = lc( unac_string "$estado-$cidade" );
    $uid =~ s/ /-/g;

    my $badge = {
        "uid"       => $uid,
        "recipient" => {
            "type"     => "email",
            "hashed"   => JSON::false,
            "identity" => "$uid\@missing.com"
        },
        "image"                  => "http://cidadessustentaveis.org.br/sites/default/files/logo.png",
        "evidence"               => "http://www.cidadessustentaveis.org.br/signatarios-candidatos",
        "issuedOn"               => time,
        "nossasaopaulo:partido"  => $partido,
        "nossasaopaulo:prefeito" => $prefeito,
        "nossasaopaulo:estado"   => $estado,
        "nossasaopaulo:cidade"   => $cidade,
        "badge"                  => "$base/pcs.json",
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
    write_file( "openbadges/pcs.json", { binmode => ':raw' }, to_json( $badge_pcs, { utf8 => 1, pretty => 1 } ) );

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