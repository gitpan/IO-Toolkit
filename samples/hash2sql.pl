#!/usr/bin/perl

use strict;
use warnings;
use IO::Toolkit;
use DBI;
use Data::Dumper;

use vars qw($getopt_loglevel $program $programname);

$getopt_loglevel = "all";
$program         = $0;      # Script Name with path
$program =~ m/\/(.+)/i;     # Only the scriptname
$programname = $1;
$program =~ m/(.+)\.pl/i;    # Without the extension
$program = $1;

logme("open");

my $dsn = "DBI:mysql:loginTimeout=300:server=xxx;database=xxx";
my $dbh =
  DBI->connect($dsn, "xxx", "xxx", {RaiseError => 1, AutoCommit => 1})
  || logme("F", "Database Error: $DBI::errstr");
logme("D", "dbconnect ok");
$dbh->{RaiseError} = 0;      # dont show error messages from dbi
$dbh->{PrintError} = 0;      # dont show error messages from dbi

my %hash = (description => "whatever",
            status      => "new",);

my $sql = IO::Toolkit::hash2sqlinsert("testtable", %hash);
logme("S", $sql);
IO::Toolkit::dosql($dbh, $sql);

while (1) {
   logme("D", "loop");
   my @results =
     IO::Toolkit::sql2data($dbh, "select * from testtable where status = \"new\"");

   for my $href (@results)
   {
       logme("D","doing something with ".$href->{description});
   }
   sleep(60); # wait a minute
}

logme("close");
$dbh->disconnect();

1;

=head1 NAME

hash2sql.pl

=head1 SYNOPSIS

./hash2sql.pl

=head1 ABSTRACT

Simple sample script about how to create SQL statements from a hash
  
=head1 DESCRIPTION

Here comes the full description

=head2 EXPORT

None by default.

=head1 SEE ALSO

   Documentation:   This POD-documentation
   Mailing List:    iotoolkit-l-subscribe-request@listserv.it-projects.com
   Support Website: http://www.linke.de

=head1 AUTHOR

Markus Linke, E<lt>markus.linke@linke.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Markus Linke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

