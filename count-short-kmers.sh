#! /bin/zsh

setopt shwordsplit

src="/space3/fangfang/amr/klebsiella"
tgt="/space3/fangfang/amr/klebsiella/counts"

kmers="3 6"
dirs="megahit_contigs"
tmpd="/tmp"

for k in $kmers; do
    for d in $dirs; do
        dd="$tgt/$d/k$k"
        echo $dd $k
        mkdir -p $dd
        pushd $dd; ls $src/$d/* | parallel -j 1 "kc.pl -tmp $tmpd -k $k {}"; popd
    done
done
