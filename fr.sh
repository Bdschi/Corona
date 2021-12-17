#!/bin/sh

wget https://www.data.gouv.fr/fr/datasets/r/19a91d64-3cd3-42fc-9943-d635491a4d76
mv 19a91d64-3cd3-42fc-9943-d635491a4d76 fr.csv
latest=`awk -F\; 'NR>1{ print $2}' fr.csv | sort | tail -1`
echo "latest data from $latest"

awk -F\; -v latest="$latest" 'function da2int(d) {
	if(!(d in i)) {
		cmd="date +\"%s\" -d" d
		cmd | getline i[d]
		close(cmd)
	}
	return i[d]
}
function today()
{
	cmd="date +\"%s\""
	cmd | getline x
	return x
}
BEGIN {
	l=da2int(latest)
}
FILENAME=="depfr.txt"&&FNR>1{
	name[$1]=$2;
	reg[$1]=$4
}
FILENAME=="fr.csv"&&FNR>1{
	dep=$1;
	jour=$2;
	P=$3;
	cl_age90=$4;
	pop=$5
	if(cl_age90=="0") {
		if(da2int($2)>l-7*3600*24) {
		#	print dep, name[dep], (l-da2int(jour))/3600/24, jour, pop, P
			s[$1]+=P
			p[$1]=pop
		}
	}
}
END {
	for(d in s) {
		print s[d]*100000.0/p[d], d, name[d], reg[d], s[d], p[d];
	}
}' depfr.txt fr.csv | sort -n > $latest.fr.txt

#egrep ' (68|25|39|71|69|26|84|13|06|83) [A-Z]' $latest.fr.txt
tail -20 $latest.fr.txt
