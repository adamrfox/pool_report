#!/usr/bin/perl

use File::Find;
use Getopt::Std;

getopts ('Dc:f:');

$DEBUG = 0;
$DEBUG = 1 if ($opt_D);
$CONF = "tiers.conf";
$CONF = $opt_c if ($opt_c);

open (CF, "< $CONF") || die "Can't open $CONF";
while (<CF>)
{
  chomp;
  my @lf = split (/[ \t]*:[ \t]*/);
  my @nf = split (/,[ \t]*/,$lf[1]);
  foreach my $node (@nf)
  {
    $pool{$node} = $lf[0];
  }
}
if ($DEBUG)
{
  foreach my $n (keys %pool)
  {
    print "DEB: Node $n - Pool $pool{$n}\n";
  }
}
find (\&wanted, @ARGV);
print "Pool:\t\tSpace:\n";
print "=============================================\n";
foreach $p (keys %space)
{
  print "$p\t\t$space{$p}\n";
}
exit (0);
#
# Subs
#
sub wanted
{
  if ( -f $File::Find::name)
  {
    $flag = 0;
#    print ($File::Find::name."\n");
    open (ISI, "isi get -DD $File::Find::name |") || die "Can't run isi get";
    while (<ISI>)
    {
      chomp;
      next if (!$flag && !/^*  Size/);
      if (!$flag)
      {
        $flag = 1;
        my @lf = split (/[ \t]+/);
        $file_size = $lf[$#lf];
        last if ($file_size == 0);
        next;
      }
      next if ($flag == 1 && !/^PROTECTION GROUPS/);
      if ($flag == 1)
      {
        $flag = 2;
        next;
      }
      my @ls = split (/[ \t]+/);
      next if ($ls[1] !~ /^[1-9]/);
      my @nf = split (/,/, $ls[1]);
      dprint ("$File::Find::name : $file_size : $nf[0] - Pool = $pool{$nf[0]}");
      $space{$pool{$nf[0]}} += $file_size;
      last;
    }
    close (ISI);
  }
}

sub dprint
{
  my @p = @_;
  print "DEB: @p\n" if ($DEBUG);
}
