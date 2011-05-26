use inc::Module::Install;

name        'SKOS-Browser';
all_from    'lib/SKOS/Browser.pm';

requires    'Plack', 0.997; 
requires    'Template', 2.22;
requires    'RDF::Trine::Store', 0.133;
requires    'Config::Any', 0.20;
requires    'Try::Tiny', 0.09;

build_requires  'Test::More', 0.88;
test_requires   'HTTP::Request::Common', 5.8;

tests 't/*.t t/*/*.t';

WriteAll;
