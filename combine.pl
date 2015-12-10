#! /usr/bin/env perl

use strict;
use Carp;

my $usage = "Usage: $0 resistant-files.list susceptible-files.list output\n\n";

my $f1 = shift @ARGV or die $usage;
my $f2 = shift @ARGV or die $usage;
my $fo = shift @ARGV or die $usage;

my @res = map { chomp; $_ } `cat $f1`;
my @sus = map { chomp; $_ } `cat $f2`;
my @files = (@res, @sus);

my $tab = '\t';
my $fmt = '0';
my $i = 1;
my $f0 = shift @files;
run("cp $f0 $fo.cmb");
$f0 = "$fo.cmb";
for my $f (@files) {
    $fmt .= ",1.".++$i;
    # my $cmd = "join -a 1 -a 2 -t \$\'$tab\' -e'0' -o '$fmt,2.2' $f0 $f >tmp && mv tmp combined";
    my $cmd = "join -a 1 -a 2 -e'0' -o '$fmt,2.2' $f0 $f >$fo.tmp && mv $fo.tmp $f0";
    print STDERR "$cmd\n";
    run($cmd);
}

open(F, ">$fo.hdr") or die "Could not open $fo.hdr";
print F join("\t", 'labels', (1) x scalar@res, (0) x scalar@sus)."\n";
close(F);

run("cat $fo.hdr $fo.cmb > $fo");
unlink("$fo.tmp", "$fo.cmb", "$fo.hdr");

sub run { system(@_) == 0 or confess("FAILED: ". join(" ", @_)); }
