package Catalyst::View::TT;

use strict;
use base qw/Catalyst::View/;
use Template;
use Template::Timer;
use NEXT;

our $VERSION = '0.18';

__PACKAGE__->mk_accessors('template');

=head1 NAME

Catalyst::View::TT - Template View Class

=head1 SYNOPSIS

# use the helper to create View
    myapp_create.pl view TT TT

# configure in lib/MyApp.pm

    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root');,
        'V::TT' => {
            # any TT configurations items go here
            INCLUDE_PATH => [
              MyApp->path_to( 'root', 'src' ), 
              MyApp->path_to( 'root', 'lib' ), 
            ],
            PRE_PROCESS => 'config/main',
            WRAPPER     => 'site/wrapper',
	    TEMPLATE_EXTENSION => '.tt',

            # two optional config items
            CATALYST_VAR => 'Catalyst',
            TIMER        => 1,
        },
    });
         
# render view from lib/MyApp.pm or lib/MyApp::C::SomeController.pm
    
    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        $c->forward('MyApp::V::TT');
    }

# access variables from template

    The message is: [% message %].
    
    # example when CATALYST_VAR is set to 'Catalyst'
    Context is [% Catalyst %]          
    The base is [% Catalyst.req.base %] 
    The name is [% Catalyst.config.name %] 
    
    # example when CATALYST_VAR isn't set
    Context is [% c %]
    The base is [% base %]
    The name is [% name %]

=head1 DESCRIPTION

This is the Catalyst view class for the L<Template Toolkit|Template>.
Your application should defined a view class which is a subclass of
this module.  The easiest way to achieve this is using the
F<myapp_create.pl> script (where F<myapp> should be replaced with
whatever your application is called).  This script is created as part
of the Catalyst setup.

    $ script/myapp_create.pl view TT TT

This creates a MyApp::V::TT.pm module in the F<lib> directory (again,
replacing C<MyApp> with the name of your application) which looks
something like this:

    package FooBar::V::TT;
    
    use strict;
     use base 'Catalyst::View::TT';

    __PACKAGE__->config->{DEBUG} = 'all';

Now you can modify your action handlers in the main application and/or
controllers to forward to your view class.  You might choose to do this
in the end() method, for example, to automatically forward all actions
to the TT view class.

    # In MyApp or MyApp::Controller::SomeController
    
    sub end : Private {
        my( $self, $c ) = @_;
        $c->forward('MyApp::V::TT');
    }

=head2 CONFIGURATION

There are a three different ways to configure your view class.  The
first way is to call the C<config()> method in the view subclass.  This
happens when the module is first loaded.

    package MyApp::V::TT;
    
    use strict;
    use base 'Catalyst::View::TT';

    MyApp::V::TT->config({
        INCLUDE_PATH => [
            MyApp->path_to( 'root', 'templates', 'lib' ),
            MyApp->path_to( 'root', 'templates', 'src' ),
        ],
        PRE_PROCESS  => 'config/main',
        WRAPPER      => 'site/wrapper',
    });

The second way is to define a C<new()> method in your view subclass.
This performs the configuration when the view object is created,
shortly after being loaded.  Remember to delegate to the base class
C<new()> method (via C<$self-E<gt>NEXT::new()> in the example below) after
performing any configuration.

    sub new {
        my $self = shift;
        $self->config({
            INCLUDE_PATH => [
                MyApp->path_to( 'root', 'templates', 'lib' ),
                MyApp->path_to( 'root', 'templates', 'src' ),
            ],
            PRE_PROCESS  => 'config/main',
            WRAPPER      => 'site/wrapper',
        });
        return $self->NEXT::new(@_);
    }
 
The final, and perhaps most direct way, is to define a class
item in your main application configuration, again by calling the
uniquitous C<config()> method.  The items in the class hash are
added to those already defined by the above two methods.  This happens
in the base class new() method (which is one reason why you must
remember to call it via C<NEXT> if you redefine the C<new()> method in a
subclass).

    package MyApp;
    
    use strict;
    use Catalyst;
    
    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root'),
        'V::TT' => {
            INCLUDE_PATH => [
                MyApp->path_to( 'root', 'templates', 'lib' ),
                MyApp->path_to( 'root', 'templates', 'src' ),
            ],
            PRE_PROCESS  => 'config/main',
            WRAPPER      => 'site/wrapper',
        },
    });

Note that any configuration items defined by one of the earlier
methods will be overwritten by items of the same name provided by the
latter methods.  

=head2 RENDERING VIEWS

The view plugin renders the template specified in the C<template>
item in the stash.  

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->forward('MyApp::V::TT');
    }

If a class item isn't defined, then it instead uses the
current match, as returned by C<$c-E<gt>match>.  In the above 
example, this would be C<message>.

The items defined in the stash are passed to the Template Toolkit for
use as template variables.

sub message : Global {
    sub default : Private {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        $c->forward('MyApp::V::TT');
    }

A number of other template variables are also added:

    c      A reference to the context object, $c
    base   The URL base, from $c->req->base()
    name   The application name, from $c->config->{ name }

These can be accessed from the template in the usual way:

<message.tt2>:

    The message is: [% message %]
    The base is [% base %]
    The name is [% name %]


The output generated by the template is stored in
C<$c-E<gt>response-E<gt>output>.

=head2 TEMPLATE PROFILING

=head2 METHODS

=over 4

=item new

The constructor for the TT view. Sets up the template provider, 
and reads the application config.

=cut

sub new {
    my ( $class, $c, $arguments ) = @_;

    my $root = $c->config->{root};

    my $config = {
        EVAL_PERL          => 0,
        TEMPLATE_EXTENSION => '',
        INCLUDE_PATH       => [ $root, "$root/base" ],
        %{ $class->config },
        %{$arguments}
    };

    # if we're debugging and/or the TIMER option is set, then we install
    # Template::Timer as a custom CONTEXT object, but only if we haven't
    # already got a custom CONTEXT defined

    if ( $config->{TIMER} ) {
        if ( $config->{CONTEXT} ) {
            $c->log->error(
                'Cannot use Template::Timer - a TT CONFIG is already defined');
        }
        else {
            $config->{CONTEXT} = Template::Timer->new(%$config);
        }
    }

    if ( $c->debug && $config->{DUMP_CONFIG} ) {
        use Data::Dumper;
        $c->log->debug( "TT Config: ", Dumper($config) );
    }

    my $self = $class->NEXT::new(
        $c,
        {
            template => Template->new($config) || do {
                my $error = Template->error();
                $c->log->error($error);
                $c->error($error);
                return undef;
              }
        },
        %{$config},
    );
    $self->config($config);

    return $self;
}

=item process

Renders the template specified in C<$c-E<gt>stash-E<gt>{template}> or
C<$c-E<gt>request-E<gt>match>. Template variables are set up from the
contents of C<$c-E<gt>stash>, augmented with C<base> set to
C<$c-E<gt>req-E<gt>base>, C<c> to C<$c> and C<name> to
C<$c-E<gt>config-E<gt>{name}>. Alternately, the C<CATALYST_VAR>
configuration item can be defined to specify the name of a template
variable through which the context reference (C<$c>) can be accessed.
In this case, the C<c>, C<base> and C<name> variables are omitted.
Output is stored in C<$c-E<gt>response-E<gt>output>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template}
      || $c->request->match . $self->config->{TEMPLATE_EXTENSION};

    unless ($template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;

    my $output;
    my $cvar = $self->config->{CATALYST_VAR};
    my $vars = {
        defined $cvar
        ? ( $cvar => $c )
        : (
            c    => $c,
            base => $c->req->base,
            name => $c->config->{name}
        ),
        %{ $c->stash() }
    };

    unless ( $self->template->process( $template, $vars, \$output ) ) {
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

This method allows your view subclass to pass additional settings to
the TT configuration hash, or to set the options as below:

=over 2

=item C<CATALYST_VAR> 

Allows you to change the name of the Catalyst context object. If set, it will also
remove the base and name aliases, so you will have access them through <context>.

For example:

    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root'),
        'V::TT' => {
            CATALYST_VAR => 'Catalyst',
        },
    });

F<message.tt2>:

    The base is [% Catalyst.req.base %]
    The name is [% Catalyst.config.name %]

=item C<TIMER>

If you have configured Catalyst for debug output, and turned on the TIMER setting,
C<Catalyst::View::TT> will enable profiling of template processing
(using L<Template::Timer>). This will embed HTML comments in the
output from your templates, such as:

    <!-- TIMER START: process mainmenu/mainmenu.ttml -->
    <!-- TIMER START: include mainmenu/cssindex.tt -->
    <!-- TIMER START: process mainmenu/cssindex.tt -->
    <!-- TIMER END: process mainmenu/cssindex.tt (0.017279 seconds) -->
    <!-- TIMER END: include mainmenu/cssindex.tt (0.017401 seconds) -->

    ....

    <!-- TIMER END: process mainmenu/footer.tt (0.003016 seconds) -->


=item C<TEMPLATE_EXTENSION>

a sufix to add when looking for templates bases on the C<match> method in L<Catalyst::Request>.

For example:

  package MyApp::C::Test;
  sub test : Local { .. } 

Would by default look for a template in <root>/test/test. If you set TEMPLATE_EXTENSION to '.tt', it will look for
<root>/test/test.tt.

=back

=back

=head2 HELPERS

The L<Catalyst::Helper::View::TT> and
L<Catalyst::Helper::View::TTSite> helper modules are provided to create
your view module.  There are invoked by the F<myapp_create.pl> script:

    $ script/myapp_create.pl view TT TT

    $ script/myapp_create.pl view TT TTSite

The L<Catalyst::Helper::View::TT> module creates a basic TT view
module.  The L<Catalyst::Helper::View::TTSite> module goes a little
further.  It also creates a default set of templates to get you
started.  It also configures the view module to locate the templates
automatically.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::View::TT>,
L<Catalyst::Helper::View::TTSite>, L<Template::Manual>

=head1 AUTHORS

Sebastian Riedel, C<sri@cpan.org>

Marcus Ramberg, C<mramberg@cpan.org>

Jesse Sheidlower, C<jester@panix.com>

Andy Wardley, C<abw@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
