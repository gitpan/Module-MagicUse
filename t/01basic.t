#!/usr/bin/perl

use File::Spec::Functions;
use Test::More tests => 6;

use vars qw/$pkg $pkg_path/;

BEGIN {
  $pkg      = 'Module::MagicUse';
  $pkg_path = catfile('Module', 'MagicUse.pm');
  
  eval { require $pkg_path };
  ok(!$@, 'required ok');
  
  eval { $pkg->import() };
  ok(!$@, 'imported ok');
};

my @modules = ( 'CGI.pm',
                catfile(qw[IO Socket.pm]),
                catfile(qw[IO Dir.pm]),
				catfile(qw[Data Dumper.pm]) );
ok(exists $INC{$_}, "$_ exists") for @modules;

exit(0);

my $q1 = CGI->new();
my $q2 = new CGI;

my $f1 = IO::Socket->new();
my $f2 = new IO::Socket();

my @l1 = (new IO::Dir("."))->read;
my @l2 = IO::Dir->new(".")->read;

my @d  = Data::Dumper->Dumper($0);
