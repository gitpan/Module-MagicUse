package Module::MagicUse;

{
  $VERSION = '0.3';
  
  use strict;
  eval q(use warnings) or local $^W = 1;

  use Carp;
  use IO::File;
  use Regexp::Common;

  my $name_re        = qr/(?:(?:\w+)(?:(?:'|::)(?:\w+)*)*)/x;
  my $constructor_re = qr{ (?: 
                               \b new \s+ ( $name_re )
                             |
                               [^\$] \b ( $name_re ) \s* -> (?: [_A-Za-z]\w+ )
                           )
                         }x;
  sub import {
    local $/;
    my $fh = IO::File->new( [caller(0)]->[1] ) or croak("Can't open: $!");
    for(grep defined, _prepare_code(<$fh>) =~ /$constructor_re/g) {
        eval "use $_;";
        croak("$@") if $@;
    }
  }

  {
    ## move this code munging into a separate module?
    use Text::Balanced qw( extract_quotelike extract_multiple );
    
    ## the following code has been bought to you by Damian Conway
    ## and the letters h, a, c and k and the number rand()

    my $ws  = qr/\s+/;
    my $id  = qr/\b(?!([ysm]|q[rqxw]?|tr)\b)\w+/;
    my $EOP = qr/\n\n|\Z/;
    my $CUT = qr/\n=cut.*$EOP/;
    my $pod_or_DATA = qr/
            ^=(?:head[1-4]|item) .*? $CUT
          | ^=pod .*? $CUT
          | ^=for .*? $EOP
          | ^=begin \s* (\S+) .*? \n=end \s* \1 .*? $EOP
          | ^__(DATA|END)__\n.*
            /smx;

    my $code_xtr = [
      $ws,
      { DONT_MATCH => $pod_or_DATA },
      $id,
      { DONT_MATCH => \&extract_quotelike }
    ];

    sub _prepare_code {
      local $_ = shift;

      my(@pieces, $instr);
      for ( extract_multiple($_, $code_xtr) ) {
        if(ref)        { push @pieces, $_; $instr = 0 }
        elsif($instr)  { $pieces[-1] .= $_ }
        else           { push @pieces, $_; $instr = 1 }
      }

      my $count = 0;
      $_ = join "", map {
             ref $_ ? $;.pack('N',$count++).$; : $_
           } @pieces;

      s<$RE{comment}{Perl}>()g;

      return $_; #, grep { ref $_ } @pieces;
    }
  }
}

q( abra cadabra! );

__END__

=head1 NAME

Module::MagicUse - Automagically include files by invoking their constructor

=head1 SYNOPSIS

  use Module::MagicUse;

  my $q = CGI->new();
  my $p = new XML::Parser();

=head1 DESCRIPTION

If you use a constructor this module will try to include the calling module.
For example

  my $q = CGI->new();

will include the C<CGI> module. The pattern of a construtor is this

  new Module

or

  Module->constructor

So it will explicitly look for a C<new> before what looks like a module name
if you're using indirect method syntax. However with direct method invocation
syntax you just need what looks like a module pointing to what looks like a
method name. This should be fairly reliable since modules and methods can be
mapped pretty simply to regexes.

=head1 REQUIREMENTS

C<Regexp::Common>
C<Text::Balanced>

=head1 BUGS

=over 2

=item x

Doesn't auto-magically include itself.

=item x

The module-grabbing probably isn't 100% accurate, and could be improved

=back

=head1 THANKS

Damian Conway for Filter::Simple, and brian_d_foy for the inspiration for
this module (see. L<http://use.perl.org/~brian_d_foy/journal/8361>).

=head1 AUTHOR

Dan Brook C<E<lt>broquaint@hotmail.comE<gt>>

=head1 SEE ALSO

L<perl>, L<import>

=cut
