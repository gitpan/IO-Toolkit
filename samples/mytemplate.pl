#!/usr/bin/perl

use strict;
use warnings;
use IO::Toolkit;
use File::Basename;

package main;
use vars qw($getopt_loglevel $program $programname);

my $program = basename($0);    
$programname = $program;
$programname =~ s/\.pl//g;

my $logfilename = $programname . ".log";
my $VERSION = sprintf "%d.%05d", '$Revision:   1.4  $' =~ /(\d+)/g;
my $description = "Script";

my $extra;
my @extra_options = (
  			{ 
		  		Spec		=>  "extra=s",
		  		Variable  	=> \$extra,
		  		Help		=> "--extra=whatever",
		  		Verbose		=> ["--extra=whatever",
					    	    "whatever whenever...",
				   	   	   ] 
			},
		    );
		
IO::Toolkit::commandline(@extra_options);

logme("open", $logfilename);
logme("M","$programname V$VERSION started --------------------------------------------------");
logme("C", "Logfile $logfilename used.");
logme("M","$programname V$VERSION ended   --------------------------------------------------");
logme("close");

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

script.pl

=head1 SYNOPSIS

./script.pl --loglevel=all

=head1 ABSTRACT

  Abstract of the script
  
=head1 DESCRIPTION

Here comes the full description

=head2 EXPORT

None by default.

=head1 SEE ALSO

   Documentation:   none
   Mailing List:    none
   Support Website: none

=head1 AUTHOR

Markus Linke, E<lt>markus.linke@linke.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Markus Linke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 AMENDMENT HISTORY

 $Log:   /hfx/var/pvcs/Murex/archives/pl/mytemplate.pl-arc  $
# 
#    Rev 1.4   05 Nov 2004 11:35:10   ml7tre
# commandline changed
# 
#    Rev 1.3   05 Nov 2004 10:32:52   ml7tre
# version changed
# 
#    Rev 1.2   29 Oct 2004 14:28:32   ml7tre
# pvcs related changes

=cut
