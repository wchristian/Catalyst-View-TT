package TestApp;

use strict;
use warnings;

use Catalyst; # qw/-Debug/;

our $VERSION = '0.01';

__PACKAGE__->config(
    name                  => 'TestApp',
    default_message       => 'hi',
    default_view          => 'Pkgconfig',
    'View::TT::Appconfig' => {
        PRE_CHOMP          => 1,
        POST_CHOMP         => 1,
        TEMPLATE_EXTENSION => '.tt',
    },
);

__PACKAGE__->setup;

sub default : Private {
    my ($self, $c) = @_;

    $c->response->redirect($c->uri_for('test'));
}

sub test : Local {
    my ($self, $c) = @_;

    $c->stash->{message} = ($c->request->param('message') || $c->config->{default_message});
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $view = 'View::TT::' . ($c->request->param('view') || $c->config->{default_view});
    $c->forward($view);
}

1;
