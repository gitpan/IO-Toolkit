use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'IO::Toolkit',
    'VERSION_FROM'	=> 'Toolkit.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Crypt::RC6','DirHandle','Digest::MD5','File::Basename','Getopt::Long'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Toolkit.pm', # retrieve abstract from module
       AUTHOR     => 'Markus Linke <markus.linke@linke.de>') : ()),
    dist => {
	PREOP => 'svn log Toolkit.pm > Changes;pod2text Toolkit.pm > README;pod2html Toolkit.pm > README.html',
    },
);
sub MY::libscan {
    my $path = $_[1];
    return '' if $path =~ /\B\.svn\b/;
    return $path;
}
