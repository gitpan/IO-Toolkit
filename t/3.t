use IOToolkit;
use Test::More tests => 7;
  
BEGIN { 
   use_ok( 'Crypt::RC6' );
   use_ok( 'IO::Toolkit' ); 
}
require_ok( 'IO::Toolkit' );

my $seed="12345678";
my $password="verysecr";
my $encrypt=IO::Toolkit::encrypt($seed,$password);
my $decrypt=IO::Toolkit::decrypt($seed,$encrypt);
cmp_ok($password,"==",$decrypt,"Encryption/Decryption");

my $timestamp = gettimestamp("filename");
cmp_ok(length($timestamp),"==",14,"Timestamp");

my %hash=(module=>"IO::Toolkit",copyright=>"Markus Linke");
my $sql=IOToolkit::hash2sqlinsert("testtable",%hash);
cmp_ok($sql,"==",'insert into testtable (copyright,module) values (\'Markus Linke\',\'IO::Toolkit\')',"hash2sqlinsert");

my $md5 = IO::Toolkit::get_md5_checksum("Toolkit.pm");
cmp_ok(length($md5),"==",32,"MD5 Checksum test");
