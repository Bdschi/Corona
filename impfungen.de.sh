#wget https://github.com/robert-koch-institut/COVID-19-Impfungen_in_Deutschland/raw/master/Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.csv
lastday=`awk -F"	" 'NR>1{print $9}' RKI_COVID19.tsv | sort | tail -1| sed 's,/,.,g'`
echo "$lastday"
awk -F"	" ' BEGIN {
rbez["010"]="Schleswig-Holstein"
rbez["020"]="Hamburg"
rbez["031"]="Braunschweig (ehe. Rz.)"
rbez["032"]="Hannover (ehe. Rz.)"
rbez["033"]="Lüneburg (ehe. Rz.)"
rbez["034"]="Wesr-Ems (ehe. Rz.)"
rbez["040"]="Bremen"
rbez["051"]="Düsseldorf"
rbez["053"]="Köln"
rbez["055"]="Münster"
rbez["057"]="Detmold"
rbez["059"]="Arnsberg"
rbez["064"]="Darmstadt"
rbez["065"]="Gießen"
rbez["066"]="Kassel"
rbez["071"]="Koblenz (ehe. Rz.)"
rbez["072"]="Trier (ehe. Rz.)"
rbez["073"]="Reinhessen-Pflaz (ehe. Rz.)"
rbez["081"]="Stuttgart"
rbez["082"]="Karlsruhe"
rbez["083"]="Freiburg"
rbez["084"]="Tübingen"
rbez["091"]="Oberbayern"
rbez["092"]="Niederbayern"
rbez["093"]="Oberpfalz"
rbez["094"]="Oberfranken"
rbez["095"]="Mittelfranken"
rbez["096"]="Unterfranken"
rbez["097"]="Schwaben"
rbez["100"]="Saarland"
rbez["110"]="Berlin"
rbez["120"]="Brandenburg"
rbez["130"]="Mecklenburg-Vorpommern"
rbez["145"]="Chemnitz"
rbez["146"]="Dresden"
rbez["147"]="Leipzig"
rbez["150"]="Sachsen-Anhalt"
rbez["160"]="Thüringen"
} FILENAME=="de.txt"&&$0~/^Kreis	'"$lastday"/'{
	fall7k=$8
} FILENAME=="de.txt"&&$0~/^NrKrei	'"$lastday"/'{
	bez=substr($3, 1, 3);
	beznr[$4]=bez
	pop[bez]+=$11
	fall7[bez]+=fall7k
} FILENAME=="Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.tsv" {
	bez=substr($2, 1, 3);
	if($4==2) {
		imp[bez]+=$5;
	}
	vollI[bez]+=$5;
} END {
	OFS=","
	n=0
	for(bez in pop) {
		print bez, rbez[bez], pop[bez], imp[bez]/pop[bez]*100, vollI[bez]/pop[bez]*100, fall7[bez]/pop[bez]*100000
		x=vollI[bez]/pop[bez]*100
		y=fall7[bez]/pop[bez]*100000
		sx+=x
		sx2+=x*x
		sxy+=x*y
		sy+=y
		sy2+=y*y;
		n++
	}
	printf "COR\t%.2f\t%.2f\n", (sxy/n-sx/n*sy/n)/sqrt(sx2/n-sx/n*sx/n)/sqrt(sy2/n-sy/n*sy/n), sy/n;
}' de.txt Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.tsv

