package Catalyst::View::TT;

use strict;
use base qw/Catalyst::Base/;
use Template;
use Template::Timer;
use NEXT;

our $VERSION = '0.11';

__PACKAGE__->mk_accessors('template');

=head1 NAME

Catalyst::View::TT - Template View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view TT TT

    # lib/MyApp/View/TT.pm
    package MyApp::View::TT;

    use base 'Catalyst::View::TT';

    __PACKAGE__->config->{DEBUG} = 'all';

    1;
    
    # Meanwhile, maybe in an '!end' action
    $c->forward('MyApp::View::TT');


=head1 DESCRIPTION

This is the C<Template> view class. Your subclass should inherit from this
class.  The plugin renders the template specified in C<< $c->stash->{template} >>
or C<< $c->request->match >>.  The template variables are set up from the
contents of C<< $c->stash >>, augmented with C<base> set to C<< $c->req->base >>,
C<c> to C<$c> and C<name> to C<< $c->config->{name} >>.  The output is
stored in C<< $c->response->output >>.


If you want to override TT config settings, you can do it there by setting
C<< __PACKAGE__->config->{OPTION} >> as shown in the synopsis. Of interest might be
C<EVAL_PERL>, which is disabled by default, and C<LOAD_TEMPLATES>, which is set to
use the provider.

If you want to use EVAL perl, add something like this:

    __PACKAGE__->config->{EVAL_PERL} = 1;
    __PACKAGE__->config->{LOAD_TEMPLATES} = undef;

If you have configured Catalyst for debug output C<Catalyst::View::TT> will
enable profiling of template processing (using C<Template::Timer>.  This will cause
HTML comments will get embedded in the output from your templates, such as:

    <!-- TIMER START: process mainmenu/mainmenu.ttml -->
    <!-- TIMER START: include mainmenu/cssindex.tt -->
    <!-- TIMER START: process mainmenu/cssindex.tt -->
    <!-- TIMER END: process mainmenu/cssindex.tt (0.017279 seconds) -->
    <!-- TIMER END: include mainmenu/cssindex.tt (0.017401 seconds) -->

    ....

    <!-- TIMER END: process mainmenu/footer.tt (0.003016 seconds) -->

You can supress template profiling when debug is enabled by setting:

    __PACKAGE__->config->{CONTEXT} = undef;


=head2 METHODS

=over 4

=item new

The constructor for the TT view. Sets up the template provider, 
and reads the application config.

=cut

sub new {
    my $self = shift;
    my $c    = shift;
    $self = $self->NEXT::new(@_);
    my $root   = $c->config->{root};
    my %config = (
        EVAL_PERL    => 0,
        INCLUDE_PATH => [ $root, "$root/base" ],
        %{ $self->config() }
    );

    if ( $c->debug && not exists $config{CONTEXT} ) {
       $config{CONTEXT} = Template::Timer->new(%config);
    }

    $self->template( Template->new( \%config ) );
    return $self;
}

=item process

Renders the template specified in C<< $c->stash->{template} >> or C<< 
$c->request->match >>.
Template variables are set up from the contents of C<< $c->stash >>, 
Jaugmented with C<base> set to C<< $c->req->base >>, C<c> to C<$c> and 
C<name> to C<< $c->config->{name} >>.  Output is stored in 
C<< $c->response->output >>.

=cut

sub process {
    my ( $self, $c ) = @_;
    $c->res->headers->content_type('text/html; charset=utf-8') 
    unless $c->res->headers->content_type();
    my $output;
    my $name = $c->stash->{template} || $c->req->match;
    unless ($name) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }
    $c->log->debug(qq/Rendering template "$name"/) if $c->debug;
    unless (
        $self->template->process(
            $name,
            {
                base => $c->req->base,
                c    => $c,
                name => $c->config->{name},
                %{ $c->stash }
            },
            \$output
        )
      )
    {
        my $error = $self->template->error;
        $error = qq/Couldn't render template "$error"/;
        $c->log->error($error);
        $c->error($error);
    }
    $c->res->output($output);
    return 1;
}

=item config

This allows your view subclass to pass additional settings to the
TT config hash.

=back

=head1 SEE ALSO

L<Catalyst>. L<Template::Manual>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
