package IO::Toolkit;

# $LastChangedDate: 2006-07-03 19:08:16 -0500 (Mon, 03 Jul 2006) $
# $LastChangedRevision: 5 $ 
# $LastChangedBy: markus.linke@linke.de $ 

use 5.008;
use strict;
use warnings;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use base qw(Exporter);
use Crypt::RC6;
use English;
use POSIX;
use DirHandle;
use Digest::MD5;
use Getopt::Long;   
use File::Basename;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT  = qw(&logme &gettimestamp);
$VERSION = 1 + sprintf("%3f",((qw$LastChangedRevision: 5 $)[-1])/1000);


sub logme
{

    my $severity = $_[0];
    my $message  = $_[1];

    if ($severity eq "open")
    {

        if (!defined($message))
        {    # If no filename is provided, use defaults
            my $program = $0;    # Script Name with path
            $program =~ m/\/(.+)\.pl/i;    # Without leading path and extension
            my $logfilename = $1 . ".log";
            $message = $logfilename;
        }

        open LOGFILE, ">>$message"
          or die "*** Fatal Error: Logfile $message cannot be opened.";
    }
    elsif ($severity eq "close")
    {
        close LOGFILE or die "*** Fatal Error: Logfile cannot be closed.";
    }

    elsif (   ($main::getopt_loglevel =~ m/$severity/)
           || ($main::getopt_loglevel eq "all"))
    {
        my $timestamp = &gettimestamp();
        my $line = "$timestamp [$main::programname] <$severity> $message\n";
        if (not $main::getopt_loglevel =~ m/-/) { print $line; }
        print LOGFILE $line;
    }

    if (($severity eq "E") || ($severity eq "F"))
    {
        $main::error_occured++;
    }

    if ($severity eq "F")
    {
        close LOGFILE;
        die "\n*** Fatal Error: $_[1]\n\n";
    }
    return 1;
}

sub gettimestamp
{
    my $format = $_[0];

    if (! defined($format)) {
       return strftime("%Y-%m-%d %H:%M:%S",localtime);
    } elsif ($format eq "filename") {
       return strftime("%Y%m%d%H%M%S",localtime);
    } else {
       return strftime($format,localtime);
    }
}

sub trim
{
    my @out = @_;
    for (@out)
    {
        s/^\s+//;    # trim left
        s/\s+$//;    # trim right
    }
    return @out == 1
      ? $out[0]      # only one to return
      : @out;        # or many
}

sub moduleinfo
{
    print "Directories searched:\n\t", join("\n\t" => @INC),
      "\nModules loaded:\n\t", join("\n\t" => sort values %INC), "\n";
    return 1;
}

sub hash2sqlinsert
{
    my $table  = shift;
    my %hash   = @_;
    my @fields = sort keys %hash;
    my @values;

    foreach $a (sort keys %hash)
    {
        push @values, $hash{$a};
    }

    return "insert into $table ("
      . join(",", @fields)
      . ") values (\'"
      . join("\',\'", @values) . "\')";
}

sub sql2data
{
    my $localdbh = $_[0];
    my $sql      = $_[1];
   
    logme("S",$sql);
    
    my $sth = $localdbh->prepare($sql);
    my $rc  = $sth->execute;

    my $num_of_fields = $sth->{NUM_OF_FIELDS}
      or logme("E", "Cannot get number of columns. SQL Syntax error?");
    my @field_names = @{$sth->{NAME}} or logme("E", "Cannot get column names");

    my $ary_ref = $sth->fetchall_arrayref() or logme("E", "Cannot fetch data");
    my $total_rows = @$ary_ref;

    my @resultlist;

    if ($@)
    {
        logme("F", "Database Error: Unable to get data $localdbh->errstr");
    }
    else
    {
        foreach my $row (@$ary_ref)
        {
            my $hashrow = {};
            my $i       = 0;
            while ($i < $num_of_fields)
            {
                if (defined(@$row[$i]))
                {
                    $hashrow->{$field_names[$i]} = @$row[$i];
                }
                else
                {
                }
                $i++;
            }
            push @resultlist, $hashrow;
        }
    }

    return @resultlist;
}

sub dosql
{
    my $locdbh = $_[0];
    my $locsql = $_[1];
    my $locsth = $locdbh->prepare_cached($locsql);
    my $ret    = $locsth->execute or logme("E", "Database error: " . $locdbh->errstr);;
    return $ret;
}

sub encrypt
{
    my $suppliedseed = shift or die "Usage: <seed> <password>\n";
    my $pwd          = shift or die "Usage: <seed> <password>\n";
    my $seed     = sprintf("%-8.8s", $suppliedseed);
    my $password = sprintf("%-16s",  $pwd);
    my $key      = "";
    map { $key .= sprintf("%02lx", ord($_)); } split("", $seed);
    my $cipher             = new Crypt::RC6 $key;
    my $ciphertext         = $cipher->encrypt($password);
    my $encrypted_password = "";
    map { $encrypted_password .= sprintf("%02lx", ord($_)) }
      split("", $ciphertext);
    return $encrypted_password;
}

sub decrypt
{
    my $seed  = shift;
    my $crypt = shift;
    $seed = sprintf("%-8.8s", $seed);
    my $key = "";
    map { $key .= sprintf("%02lx", ord($_)); } split("", $seed);
    my $cipher = new Crypt::RC6 $key;
    my $ep     = "";

    while ($crypt =~ m/../g) { $ep .= chr(hex($MATCH)); }
    my $pwd = $cipher->decrypt($ep);
    $pwd =~ s/\s//g;
    return $pwd;
}

sub pid {
   my $status = $_[0];
   my $file   = $_[1];
   
   if   ($status eq "exclusive") {
      if (-e $file) { die "PID File $file exists! Program ends here.\n";}
      open PID,">$file";
      print PID $$;
      close PID;
   } if ($status eq "overwrite") {
      open PID,">$file";
      print PID $$;
      close PID;
   } if ($status eq "remove") {
      unlink $file;
   }
}

sub filelist {

   # Desc: Filelist returns a list of files in a directory
   # Para: Directory

   my $dir = shift;
   my $dh = DirHandle->new($dir)   or die "can't opendir $dir: $!";
   return sort                       # sort pathnames
#         grep { -f   }              # -l links -f files
          map  { "$dir/$_" }         # create full paths
          grep {  !/^\./   }         # filter out dot files
          $dh->read( );              # read all entries
}

sub get_md5_checksum{

   # Desc: Returns MD5 checksum for given filename

   my $filename=$_[0];
   my $md5 = Digest::MD5->new;
   open(my $fh, "< $filename") or die "cant open file $filename";
   $md5->reset;
   $md5->addfile($fh);
   close $fh;
   return $md5->hexdigest;
}

sub commandline {
	my @extra_options = @_;
	my $help;
	my $verbose;
	my @default_options = (
		{ 
		  Spec		=>  "loglevel=s",
		  Variable  	=> \$main::getopt_loglevel,
		  Help		=> "--loglevel=FEMSW-",
		  Verbose	=> ["--loglevel=Which messages should be logged",
		  				"F=FATAL",
						"E=ERROR",
						"M=MESSAGE",
						"-=No output to STDOUT",
						"all=Show all messages",
						] 
		},
		{ 
		  Spec		=>  "help!",
		  Variable  	=> \$help,
		  Help		=> "--help",
		  Verbose	=> ["--help - Display Usage information and exit"]
		},
		{ 
		  Spec		=>  "verbose!",
		  Variable  	=> \$verbose,
		  Help		=> "--verbose",
		  Verbose	=> ["--verbose - Display more detailed Usage information and exit"]
		},
		);
	my %options = ();
	foreach my $o (@default_options, @extra_options) {
		$options{$o->{Spec}} = $o->{Variable};
	}
	my $result = GetOptions(%options);
	die("GetOptions failed: $!\n") unless $result;
	if (defined($help) or defined($verbose)) {
		my $usage = get_usage($verbose, @default_options, @extra_options);
		print $usage;
		exit(0);
	}
	
	$main::getopt_loglevel="all" unless defined($main::getopt_loglevel);
}

sub get_usage {
	my ($verbose, @opts) = @_;
	my $filename = basename($0);
	my $usage = "Usage: $filename ";
	my @usage = ();
	my $indent = " " x length($usage);

	foreach my $opt (@opts) {
		if ($verbose) {
			my $firstline = 1;
			foreach my $desc (@{ $opt->{Verbose} }) {
				my $indent = $firstline ? "" : "\t";
				push(@usage, "$indent$desc");
				$firstline = 0;
			}
		}
		else {
				push(@usage, $opt->{Help});
		}
	}
	return wantarray ? @usage : $usage.join("\n$indent", @usage)."\n";
}


1;

__END__

=head1 NAME

IO::Toolkit

=head1 ABSTRACT

IO::Toolkit - Perl extension to create logfiles

=head1 PREREQUISITS

This module needs Crypt::RC6 for its encryption/decryption routine.
Digest::MD5 and DirHandle used for checksum routines.

=head1 SYNOPSIS

Sample Script (please also have a look into the samples directory):

   use IO::Toolkit;
   use File::Basename;

   package main;
   use vars qw($getopt_loglevel $program $programname);

   my $program = basename($0);    
   $programname = $program;
   $programname =~ s/\.pl//g;

   my $logfilename = $programname . ".log";
   my $VERSION = sprintf "%d.%05d", '$Revision: 5 $' =~ /(\d+)/g;
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
   
This displays and creates a logfile like this:

   2004-11-14 13:07:48 [mytemplate] <M> mytemplate V1.00004 started --------------------------------------------------
   2004-11-14 13:07:48 [mytemplate] <C> Logfile mytemplate.log used.
   2004-11-14 13:07:48 [mytemplate] <M> mytemplate V1.00004 ended   --------------------------------------------------

=head1 IMPORTANT NOTICE

If you are looking for a better logging-module, please check Log4Perl instead.

=head1 DESCRIPTION

Provides a human-readable logfile and is ment to replace "print" and "die" in your programs.

This module was written to provide an easy way to log messages. It
checks for an option --loglevel=EMCDQ- where each character stands 
for a certain level. e.g.

   E   = Error
   S   = System
   M   = Message
   D   = Debug
   -   = Silent
   all = All messages

You can use all characters you would like to use. These are just examples.

the minus ("-") has a special meaning: supresses output to the screen and
ONLY logs them to the file. Please see the sample script for more details.

The function gettimestamp returns the current time in the format used for the logfile. 
If you specifiy the format &gettimestamp("filename") it returns something like
this: 20041009131500

=head2 IO::Toolkit::logme("M","Message")

The first parameter specifies the severity of the message. The message is only logged, if 
$getopt_loglevel contains that severity.

Because IO::Toolkit::logme is exported, you can just use logme("M","message") in your scripts. 

=head2 IO::Toolkit::moduleinfo 

prints a list of loaded modules.

=head2 IO::Toolkit::trim 

trims a variable.

=head2 IO::Toolkit::hash2sql 

creates SQL code to insert a hash into a table.

Example:

   use IO::Toolkit;

   my %hash=(
      firstname=>"Markus",
      lastname=>"Linke",
   );

   print IO::Toolkit::hash2sqlinsert("tablename",%hash)."\n";
   
Result:

   insert into tablename (firstname,lastname) values ("Markus","Linke") 

IO::Toolkit::sql2data executes SQL statement and creates a array of hashs

   use IO::Toolkit;
   use Data::Dumper;
   print Dumper(IO::Toolkit::sql2data($dbh,"select * from environments"));


=head2 IO::Toolkit::encrypt and IO::Toolkit::decrypt

needs two strings as parameters (e.g. seed and password) and returns an
encrypted/decrypted value.

=head2 IO::Toolkit::pid("exclusive|overwrite|remove","/tmp/filename.pid");

Create or delete PID file. If set to exclusive, the program dies if the 
file already exists. 

=head2 my $md5 = IO::Toolkit::get_md5_checksum("Toolkit.pm");

Create a MD5 checksum for the filename provided.

=head1 EXPORT

logme and gettimestamp are exported.

=head1 SEE ALSO

   http://www.linke.de for my personal homepage
   Submit bugs at http://bugzilla.it-projects.com
   Version Control provided by http://svn.it-projects.com
      
=head1 AUTHOR

Markus Linke, markus.linke@linke.de

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2006 by Markus Linke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

