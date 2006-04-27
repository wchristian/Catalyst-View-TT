package Catalyst::View::TT;

use strict;
use base qw/Catalyst::View/;
use Template;
use Template::Timer;
use NEXT;

our $VERSION = '0.23';

__PACKAGE__->mk_accessors('template');
__PACKAGE__->mk_accessors('include_path');

*paths = \&include_path;

=head1 NAME

Catalyst::View::TT - Template View Class

=head1 SYNOPSIS

# use the helper to create View
    myapp_create.pl view TT TT

# configure in lib/MyApp.pm

    MyApp->config(
        name     => 'MyApp',
        root     => MyApp->path_to('root');,
        'View::TT' => {
            # any TT configurations items go here
            INCLUDE_PATH => [
              MyApp->path_to( 'root', 'src' ), 
              MyApp->path_to( 'root', 'lib' ), 
            ],
            PRE_PROCESS        => 'config/main',
            WRAPPER            => 'site/wrapper',
            TEMPLATE_EXTENSION => '.tt',

            # two optional config items
            CATALYST_VAR => 'Catalyst',
            TIMER        => 1,
        },
    );
         
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

=head2 DYNAMIC INCLUDE_PATH

Sometimes it is desirable to modify INCLUDE_PATH for your templates at run time.
 
Additional paths can be added to the start of INCLUDE_PATH via the stash as
follows:

    $c->stash->{additional_template_paths} =
        [$c->config->{root} . '/test_include_path'];

If you need to add paths to the end of INCLUDE_PATH, there is also an
include_path() accessor available:

    push( @{ $c->view('TT')->include_path }, qw/path/ );

Note that if you use include_path() to add extra paths to INCLUDE_PATH, you
MUST check for duplicate paths. Without such checking, the above code will add
"path" to INCLUDE_PATH at every request, causing a memory leak.

A safer approach is to use include_path() to overwrite the array of paths
rather than adding to it. This eliminates both the need to perform duplicate
checking and the chance of a memory leak:

    @{ $c->view('TT')->include_path } = qw/path another_path/;

If you are calling C<render> directly then you can specify dynamic paths by 
having a C<additional_template_paths> key with a value of additonal directories
to search. See L<CAPTURING TEMPLATE OUTPUT> for an example showing this.

=head2 RENDERING VIEWS

The view plugin renders the template specified in the C<template>
item in the stash.  

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->forward('MyApp::V::TT');
    }

If a class item isn't defined, then it instead uses the
current match, as returned by C<< $c->match >>.  In the above 
example, this would be C<message>.

The items defined in the stash are passed to the Template Toolkit for
use as template variables.

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


The output generated by the template is stored in C<< $c->response->body >>.

=head2 CAPTURING TEMPLATE OUTPUT

If you wish to use the output of a template for some other purpose than
displaying in the response, e.g. for sending an email, this is possible using
L<Catalyst::Plugin::Email> and the L<render> method:

  sub send_email : Local {
    my ($self, $c) = @_;
    
    $c->email(
      header => [
        To      => 'me@localhost',
        Subject => 'A TT Email',
      ],
      body => $c->view('TT')->render($c, 'email.tt', {
        additional_template_paths => [ $c->config->{root} . '/email_templates'],
        email_tmpl_param1 => 'foo'
        }
      ),
    );
  # Redirect or display a message
  }

=head2 TEMPLATE PROFILING

See L<C<TIMER>> property of the L<config> method.

=head2 METHODS

=over 4

=item new

The constructor for the TT view. Sets up the template provider, 
and reads the application config.

=cut

sub _coerce_paths {
    my ( $paths, $dlim ) = shift;
    return () if ( !$paths );
    return @{$paths} if ( ref $paths eq 'ARRAY' );

    # tweak delim to ignore C:/
    unless ( defined $dlim ) {
        $dlim = ( $^O eq 'MSWin32' ) ? ':(?!\\/)' : ':';
    }
    return split( /$dlim/, $paths );
}

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $config = {
        EVAL_PERL          => 0,
        TEMPLATE_EXTENSION => '',
        %{ $class->config },
        %{$arguments},
    };
    if ( ! (ref $config->{INCLUDE_PATH} eq 'ARRAY') ) {
        my $delim = $config->{DELIMITER};
        my @include_path
            = _coerce_paths( $config->{INCLUDE_PATH}, $delim );
        if ( !@include_path ) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir( $root, 'base' );
            @include_path = ( "$root", "$base" );
        }
        $config->{INCLUDE_PATH} = \@include_path;
    }



    # if we're debugging and/or the TIMER option is set, then we install
    # Template::Timer as a custom CONTEXT object, but only if we haven't
    # already got a custom CONTEXT defined

    if ( $config->{TIMER} ) {
        if ( $config->{CONTEXT} ) {
            $c->log->error(
                'Cannot use Template::Timer - a TT CONTEXT is already defined'
            );
        }
        else {
            $config->{CONTEXT} = Template::Timer->new(%$config);
        }
    }

    if ( $c->debug && $config->{DUMP_CONFIG} ) {
        use Data::Dumper;
        $c->log->debug( "TT Config: ", Dumper($config) );
    }
    if ( $config->{PROVIDERS} ) {
        my @providers = ();
        if ( ref($config->{PROVIDERS}) eq 'ARRAY') {
            foreach my $p (@{$config->{PROVIDERS}}) {
                my $pname = $p->{name};
                my $prov = 'Template::Provider';
                if($pname eq '_file_')
                {
                    $p->{args} = { %$config };
                }
                else
                {
                    $prov .="::$pname" if($pname ne '_file_');
                }
                eval "require $prov";
                if(!$@) {
                    push @providers, "$prov"->new($p->{args});
                }
                else
                {
                    $c->log->warn("Can't load $prov, ($@)");
                }
            }
        }
        delete $config->{PROVIDERS};
        if(@providers) {
            $config->{LOAD_TEMPLATES} = \@providers;
        }
    }

    my $self = $class->NEXT::new(
        $c, { %$config }, 
    );

    # Set base include paths. Local'd in render if needed
    $self->include_path($config->{INCLUDE_PATH});
    
    $self->config($config);

    # Creation of template outside of call to new so that we can pass [ $self ]
    # as INCLUDE_PATH config item, which then gets ->paths() called to get list
    # of include paths to search for templates.
   
    # Use a weakend copy of self so we dont have loops preventing GC from working
    my $copy = $self;
    Scalar::Util::weaken($copy);
    $config->{INCLUDE_PATH} = [ sub { $copy->paths } ];
    
    $self->{template} = 
        Template->new($config) || do {
            my $error = Template->error();
            $c->log->error($error);
            $c->error($error);
            return undef;
        };


    return $self;
}

=item process

Renders the template specified in C<< $c->stash->{template} >> or
C<< $c->action >> (the private name of the matched action.  Calls L<render> to
perform actual rendering. Output is stored in C<< $c->response->body >>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template}
      ||  $c->action . $self->config->{TEMPLATE_EXTENSION};

    unless ($template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $output = $self->render($c, $template);

    if (UNIVERSAL::isa($output, 'Template::Exception')) {
        my $error = qq/Coldn't render template "$output"/;
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

=item render($c, $template, \%args)

Renders the given template and returns output, or a L<Template::Exception>
object upon error. 

The template variables are set to C<%$args> if $args is a hashref, or 
$C<< $c->stash >> otherwise. In either case the variables are augmented with 
C<base> set to C< << $c->req->base >>, C<c> to C<$c> and C<name> to
C<< $c->config->{name} >>. Alternately, the C<CATALYST_VAR> configuration item
can be defined to specify the name of a template variable through which the
context reference (C<$c>) can be accessed. In this case, the C<c>, C<base> and
C<name> variables are omitted.

C<$template> can be anything that Template::process understands how to 
process, including the name of a template file or a reference to a test string.
See L<Template::process|Template/process> for a full list of supported formats.

=cut

sub render {
    my ($self, $c, $template, $args) = @_;

    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;

    my $output;
    my $vars = { 
        (ref $args eq 'HASH' ? %$args : %{ $c->stash() }),
        $self->template_vars($c)
    };

    local $self->{include_path} = 
        [ @{ $vars->{additional_template_paths} }, @{ $self->{include_path} } ]
        if ref $vars->{additional_template_paths};

    unless ($self->template->process( $template, $vars, \$output ) ) {
        return $self->template->error;  
    } else {
        return $output;
    }
}

=item template_vars

Returns a list of keys/values to be used as the catalyst variables in the
template.

=cut

sub template_vars {
    my ( $self, $c ) = @_;

    my $cvar = $self->config->{CATALYST_VAR};

    defined $cvar
      ? ( $cvar => $c )
      : (
        c    => $c,
        base => $c->req->base,
        name => $c->config->{name}
      )
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
