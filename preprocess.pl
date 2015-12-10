#! /usr/bin/env perl

use strict;

use Carp;
use Data::Dumper;
use File::Temp qw/tempfile/;
use Getopt::Long;

my $usage = "Usage: $0 antibiotic.metadata kmer.counts.folder \n\n";
# $0 /disks/jul302015vol/jdavis/AMR_Kmers/Kmer_Files/Wesleys_Klebsiella/Log_Files/TIG.log /disks/jul302015vol/jdavis/AMR_Kmers/Kmer_Files/Wesleys_Klebsiella/KMERS


my ($help, $frac, $kmer, $binary);

GetOptions("h|help" => \$help,
           "frac=f" => \$frac,
           "kmer=i" => \$kmer,
           "binary" => \$binary,
	  ) or die("Error in command line arguments\n");

$help and die $usage;

my $drug_meta   = shift @ARGV;
my $kmer_folder = shift @ARGV;

$kmer_folder && -d $kmer_folder && $drug_meta && -f $drug_meta or die $usage;

$frac ||= 1.0;
$kmer ||= 31;

my ($res, $sus) = read_drug_metadata($drug_meta, $kmer_folder);

my $n_res = $frac < 1 ? int($frac * scalar@$res) : scalar@$res;
my $n_sus = $frac < 1 ? int($frac * scalar@$sus) : scalar@$sus;

my @res = @$res[0..$n_res-1];
my @sus = @$sus[0..$n_sus-1];


if ($kmer >= 10) {
    my ($fh1, $fname1) = tempfile();
    my ($fh2, $fname2) = tempfile();

    print $fh1 join("\n", @res)."\n";
    print $fh2 join("\n", @sus)."\n";

    close($fh1);
    close($fh2);

    my $use_counts = $binary ? "" : '--use-kmer-counts';

    # run("kmerge --use-kmer-counts -r 1 -d $kmer_folder $fname1 $fname2");
    run("kmerg2-ada.epsilon4 $use_counts -d $kmer_folder $fname1 $fname2");
} else {
    print join("\t", 'labels', (1) x scalar@res, (0) x scalar@sus)."\n";
    @res = map { "$kmer_folder/$_.jf" } @res;
    @sus = map { "$kmer_folder/$_.jf" } @sus;

    my @cmd = ("count_in_file", @res, @sus);
    open(F, ">tmp") or die "Could not open tmp";
    print F join(" ", @cmd)."\n";
    close(F);
    run(join(" ", @cmd));
}

# } else {
#     my ($fh1, $fname1) = tempfile();
#     my ($fh2, $fname2) = tempfile();

#     print $fh1 join("\n", map { "$kmer_folder/$_".".k$kmer" } @res)."\n";
#     print $fh2 join("\n", map { "$kmer_folder/$_".".k$kmer" } @sus)."\n";

#     close($fh1);
#     close($fh2);

#     my $fo = $drug_meta;
#     $fo =~ s/^.*\.//;
#     run("/space3/fangfang/amr/scripts/combine.pl $fname1 $fname2 $kmer_folder/$fo.k$kmer");
# }

sub read_drug_metadata {
    my ($drug_meta, $kmer_folder) = @_;
    my $ext = get_kmer_count_ext();
    my @lines = `cat $drug_meta`;
    my (@res, @sus);
    for (@lines) {
        chomp;
        my ($genome, $pheno) = split/\s+/;
        my $gfile = "$kmer_folder/$genome$ext";
        # print STDERR $gfile."\n";
        next if $kmer_folder && ! -s $gfile;
        push @res, $genome if $pheno =~ /^R/i;
        push @sus, $genome if $pheno =~ /^S/i;
    }
    (\@res, \@sus);
}

sub get_kmer_count_ext {
    # return $kmer >= 10 ? ".k$kmer" : ".jf";
    return $kmer >= 10 ? ".kmc_suf" : ".jf";
}

sub run { system(@_) == 0 or confess("FAILED: ". join(" ", @_)); }
