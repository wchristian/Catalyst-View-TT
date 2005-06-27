package Catalyst::View::TT;

use strict;
use base qw/Catalyst::Base/;
use Template;
use Template::Timer;
use NEXT;

our $VERSION = '0.12';

__PACKAGE__->mk_accessors('template');

=head1 NAME

Catalyst::View::TT - Template View Class

=head1 SYNOPSIS

    # use the helper
    myapp_create.pl view TT TT

    # lib/MyApp/View/TT.pm
    package MyApp::View::TT;

    use base 'Catalyst::View::TT';

    __PACKAGE__->config->{DEBUG} = 'all';

    # in practice you'd probably set this from a config file;
    # defaults to $c->config->root
    __PACKAGE__->config->{INCLUDE_PATH} =
       '/usr/local/generic/templates:/usr/local/myapp/templates';

    1;
    
    # Meanwhile, maybe in a private C<end> action
    $c->forward('MyApp::View::TT');


=head1 DESCRIPTION

This is the Catalyst view class for the L<Template
Toolkit|Template>. Your application subclass should inherit from this
class. This plugin renders the template specified in
C<$c-E<gt>stash-E<gt>{template}>, or failing that,
C<$c-E<gt>request-E<gt>match>. The template variables are set up from
the contents of C<$c-E<gt>stash>, augmented with template variable
C<base> set to Catalyst's C<$c-E<gt>req-E<gt>base>, template variable
C<c> to Catalyst's C<$c>, and template variable C<name> to Catalyst's
C<$c-E<gt>config-E<gt>{name}>. The output is stored in
C<$c-E<gt>response-E<gt>output>.

If you want to override TT config settings, you can do it in your
application's view class by setting
C<__PACKAGE__-E<gt>config-E<gt>{OPTION}>, as shown in the Synopsis. Of
interest might be C<EVAL_PERL>, which is disabled by default,
C<INCLUDE_PATH>, and C<LOAD_TEMPLATES>, which is set to use the
provider.

If you want to use C<EVAL_PERL>, add something like this:

    __PACKAGE__->config->{EVAL_PERL} = 1;
    __PACKAGE__->config->{LOAD_TEMPLATES} = undef;

If you have configured Catalyst for debug output, C<Catalyst::View::TT>
will enable profiling of template processing (using
L<Template::Timer>). This will embed HTML comments in the output from
your templates, such as:

    <!-- TIMER START: process mainmenu/mainmenu.ttml -->
    <!-- TIMER START: include mainmenu/cssindex.tt -->
    <!-- TIMER START: process mainmenu/cssindex.tt -->
    <!-- TIMER END: process mainmenu/cssindex.tt (0.017279 seconds) -->
    <!-- TIMER END: include mainmenu/cssindex.tt (0.017401 seconds) -->

    ....

    <!-- TIMER END: process mainmenu/footer.tt (0.003016 seconds) -->

You can suppress template profiling when debug is enabled by setting:

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

Renders the template specified in C<$c-E<gt>stash-E<gt>{template}> or
C<$c-E<gt>request-E<gt>match>. Template variables are set up from the
contents of C<$c-E<gt>stash>, augmented with C<base> set to
C<$c-E<gt>req-E<gt>base>, C<c> to C<$c> and C<name> to
C<$c-E<gt>config-E<gt>{name}>. Output is stored in
C<$c-E<gt>response-E<gt>output>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template} || $c->request->match;

    unless ($template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;
    
    my $output;

    unless (
        $self->template->process(
            $template,
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
        return 0;
    }
    
    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);

    return 1;
}

=item config

This allows your view subclass to pass additional settings to the
TT config hash.

=back

=head1 SEE ALSO

L<Catalyst>, L<Template::Manual>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>
Jesse Sheidlower, C<jester@panix.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
