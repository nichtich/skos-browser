package SKOS::Browser;

=head1 NAME

SKOS::Browser - Browseable Linked Data interface to SKOS vocabularies

=cut

use strict;
use warnings;
use 5.10.0;

use parent 'Plack::Component';
use Plack::Util::Accessor qw(config);
use Plack::Request;
use Template;
use RDF::Trine::Store;
use Config::Any;
use File::Basename qw(dirname fileparse);
use File::Spec::Functions qw(catfile rel2abs);
use Try::Tiny;
use Data::Dumper;

our $VERSION = '0.1';

=head1 METHODS

=head2 prepare_app

Initialized the application by setting the configuration file, and calling load_config().

=cut

sub prepare_app {
    my $self = shift;
    $self->load_config;
}

=head2 load_config ( [ $file ] )

Load the configuration file, as set with the config parameter or with the
SKOS_BROWSER_CONFIG environment variable. You can also pass a new file name or
undef to force checking SKOS_BROWSER_CONFIG.

=cut

sub load_config {
    my $self = shift;
    $self->config( @_ ) if @_;
    $self->config( $ENV{SKOS_BROWSER_CONFIG} ) unless defined $self->config;
    
    # try to load config file
    my $config = eval { 
        Config::Any->load_files( { files => [ $self->config ], use_ext => 1 } ); 
    } if defined $self->config;

    if ($config && @$config) {
        ($_,$config) = %{ $config->[0] };
        $self->fatal( undef );
    } else {
        $self->fatal( $@ || "Failed to load configuration file " . ($self->config || "") );
        return;
    }

    $self->{configtime} = (stat $self->{config})[9];

    # try to find files relative to config file
    my $configdir = dirname(rel2abs($self->{config}));
    my $abs = sub { return $_[0] =~ /^\// ? $_[0] : catfile($configdir, $_[0]); };
    
    # apply configuration
    $self->{title} = $config->{title};
    $self->{store} = undef;
    $self->{template} = undef; 

    if ($config->{store}) {
        if ($config->{store} =~ /^Memory;file:([^\/].*)$/) {
            $config->{store} = 'Memory;file:' . catfile($configdir, $1);
        }
        $self->{store} = try { 
            RDF::Trine::Store->new_with_string( $config->{store} );
        } catch {
            $self->fatal( "Failed to initialize store: $_" );
        }
    }

    if ($config->{templates}) {
        $self->{template} = try { 
               Template->new({
                INCLUDE_PATH => $abs->( $config->{templates} ),
                INTERPOLATE  => 1
            });
        } catch { 
            $self->fatal( "Failed to initialize templates: $_" );          
        };
    }
}

=head2 reload_config ( [ $config ] )

Reload the configuration file if it is been modified. Reloading is forced if
you pass a file name or undef.

=cut

sub reload_config {
    my $self = shift;
   
    if ( @_ ) {
        $self->config( @_ );
        return;
    }

    return unless defined $self->config and $self->{configtime};

    my $mtime = try { (stat $self->{config})[9] };

    $self->load_config if $mtime and $mtime > $self->{configtime};
}


# called to set, unset or get configuration errors
sub fatal {
    my $self = shift;

    if ( @_ ) {
        my $error = shift;
        $error =~ s/ at \/.*//s if defined $error; # remove location
        $self->{fatal} = $error;

        # TODO: use log4perl instead
        print STDERR $self->{fatal}."\n" if defined $error;

        return; # to return undef from a catch block
    } 

    return $self->{fatal}; 
}

sub server_error {
    my ($self, $error) = @_;

    return [ 500, [ 'Content-type' => 'text/plain' ], [ $error ] ]
}

sub size {
    my $self = shift;
    return 0 unless $self->{store};
    return $self->{store}->size;
}

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    $self->reload_config;

    my $res = $req->new_response(200);

    return $self->server_error( $self->fatal ) if $self->fatal;

    if ( $self->{template} ) {
        my $t = $self->{template};
        my $template = "index.html";
        my $out;
        my %vars = (
            title   => $self->{title} || "SKOS Browser",
            size    => $self->size,
            path    => $req->path_info,
            version => $VERSION,
        );
        if ( $t->process($template, \%vars, \$out) ) {
            $res->content_type('text/html');
            $res->body( $out );
            return $res->finalize;
        } else {
            return $self->server_error( "Template error: " . $t->error );
        }
    }

    # some content can be delivered even without templates
    
    return [ 
        200, 
        [ 'Content-type' => 'text/html' ],
        [ '<!DOCTYPE html>',
          '<body><h1>Hello world</h1>',
          'config: ' . (defined $self->config ? $self->config : "-"),
          '<pre>',
          Dumper($env),
          '</pre></body></html>',
        ],
    ];
}

1;

__END__

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2011 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

In addition you may fork this library under the terms of the 
GNU Affero General Public License.

=cut
