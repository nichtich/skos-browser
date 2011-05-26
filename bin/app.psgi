#!/usr/bin/perl

use strict;

use Plack::Builder;
use SKOS::Browser;

use constant ENABLE_DEBUG => 1;

=head1 DESCRIPTION

Configuration is done using L<Config::JFDI>, so you can use json, YAML, or INI
style configuration files. You can either specify a file in instanciation:

  my $app = SKOS::Browser->new( config => "mybrowser.json" );

If no file is specified, the environment variable SKOS_BROWSER_CONFIG is used
to find the configuration file.

=cut

#my $config = 
#
#        my $config = Config::JFDI->new( name => 'SKOS::Browser' );
#        if ($config and $config->found) {
#            $self->config( $config->found );
#        }

my $app = SKOS::Browser->new();

# enable middleware, based on runtime conditions
builder {

    # Displays stack trace when the app dies 
    enable_if { ENABLE_DEBUG } 'StackTrace';

    $app;
}
