age=$(( (`date +%s` - `stat -L --format %Y RKI_COVID19.csv`) > (12*60*60) ))
if [ $age -eq 0 ]
then
	echo "file 'RKI_COVID19.csv' is less than 12 hours old -> no download"
else
	wget https://www.arcgis.com/sharing/rest/content/items/f10774f1c63e40168479a1feb6c7ca74/data
	mv data RKI_COVID19.csv
	./csv2tsv.py < RKI_COVID19.csv > RKI_COVID19.tsv
fi

age=$(( (`date +%s` - `stat -L --format %Y Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.csv`) > (12*60*60) ))
if [ $age -eq 0 ]
then
	echo "file 'Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.csv' is less than 12 hours old -> no download"
else
	rm Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.csv
	wget https://github.com/robert-koch-institut/COVID-19-Impfungen_in_Deutschland/raw/master/Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.csv
	./csv2tsv.py < Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.csv > Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.tsv
fi

#Dem Dashboard liegen aggregierte Daten der gemäß IfSG von den Gesundheitsämtern an das RKI übermittelten Covid-19-Fälle zu Grunde
#Mit den Daten wird der tagesaktuelle Stand (00:00 Uhr) abgebildet und es werden die Veränderungen bei den Fällen und Todesfällen zum Vortag dargstellt
#In der Datenquelle sind folgende Parameter enthalten:
##IdBundesland: Id des Bundeslands des Falles mit 1=Schleswig-Holstein bis 16=Thüringen
##Bundesland: Name des Bundeslanes
##Landkreis ID: Id des Landkreises des Falles in der üblichen Kodierung 1001 bis 16077=LK Altenburger Land
##Landkreis: Name des Landkreises
##Altersgruppe: Altersgruppe des Falles aus den 6 Gruppe 0-4, 5-14, 15-34, 35-59, 60-79, 80+ sowie unbekannt
##Altersgruppe2: Altersgruppe des Falles aus 5-Jahresgruppen 0-4, 5-9, 10-14, ..., 75-79, 80+ sowie unbekannt
##Geschlecht: Geschlecht des Falles M0männlich, W=weiblich und unbekannt
##AnzahlFall: Anzahl der Fälle in der entsprechenden Gruppe
##AnzahlTodesfall: Anzahl der Todesfälle in der entsprechenden Gruppe
##Meldedatum: Datum, wann der Fall dem Gesundheitsamt bekannt geworden ist
##Datenstand: Datum, wann der Datensatz zuletzt aktualisiert worden ist
##NeuerFall: 
###0: Fall ist in der Publikation für den aktuellen Tag und in der für den Vortag enthalten
###1: Fall ist nur in der aktuellen Publikation enthalten
###-1: Fall ist nur in der Publikation des Vortags enthalten
###damit ergibt sich: Anzahl Fälle der aktuellen Publikation als Summe(AnzahlFall), wenn NeuerFall in (0,1); Delta zum Vortag als Summe(AnzahlFall) wenn NeuerFall in (-1,1)
##NeuerTodesfall:
###0: Fall ist in der Publikation für den aktuellen Tag und in der für den Vortag jeweils ein Todesfall
###1: Fall ist in der aktuellen Publikation ein Todesfall, nicht jedoch in der Publikation des Vortages
###-1: Fall ist in der aktuellen Publikation kein Todesfall, jedoch war er in der Publikation des Vortags ein Todesfall
###-9: Fall ist weder in der aktuellen Publikation noch in der des Vortages ein Todesfall
###damit ergibt sich: Anzahl Todesfälle der aktuellen Publikation als Summe(AnzahlTodesfall) wenn NeuerTodesfall in (0,1); Delta zum Vortag als Summe(AnzahlTodesfall) wenn NeuerTodesfall in (-1,1)
##Referenzdatum: Erkrankungsdatum bzw. wenn das nicht bekannt ist, das Meldedatum
##AnzahlGenesen: Anzahl der Genesenen in der entsprechenden Gruppe
##NeuGenesen:
###0: Fall ist in der Publikation für den aktuellen Tag und in der für den Vortag jeweils Genesen
###1: Fall ist in der aktuellen Publikation Genesen, nicht jedoch in der Publikation des Vortages
###-1: Fall ist in der aktuellen Publikation nicht Genesen, jedoch war er in der Publikation des Vortags Genesen
###-9: Fall ist weder in der aktuellen Publikation noch in der des Vortages Genesen 
###damit ergibt sich: Anzahl Genesen der aktuellen Publikation als Summe(AnzahlGenesen) wenn NeuGenesen in (0,1); Delta zum Vortag als Summe(AnzahlGenesen) wenn NeuGenesen in (-1,1)
##IstErkrankungsbeginn: 1, wenn das Refdatum der Erkrankungsbeginn ist, 0 sonst
lastday=`awk -F"	" 'NR>1{print $9}' RKI_COVID19.tsv | sort | tail -1`
awk -F"	" 'function datum2int(dat) {
	if(!(dat in i2d)) {
		cmd=sprintf("date +\"%%s\" -d \"%s\"", dat);
		cmd | getline i2d[dat];
		close(cmd);
	}
	return i2d[dat];
}
function int2datum(idat) {
	if(!(idat in d2i)) {
		cmd=sprintf("date +\"%%Y/%%m/%%d 00:00:00\" -d \"@%s\"", idat);
		cmd | getline d2i[idat];
		close(cmd);
	}
	return d2i[idat];
}
FNR>1&&FILENAME=="kreise.tsv"{
	ew[$1]=$2;
}
FNR>1&&FILENAME=="Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.tsv"{
#Impfdatum,LandkreisId_Impfort,Altersgruppe,Impfschutz,Anzahl
	impfung[$2]+=$5
	if($4==2)
		vollGeimpft[$2]+=$5
}
FNR>1&&FILENAME=="RKI_COVID19.tsv"{
	FID=$1
	IdBundesland=$2
	Bundesland=$3
	Landkreis=$4
	Altersgruppe=$5
	Geschlecht=$6
	AnzahlFall=$7
	AnzahlTodesfall=$8
	Meldedatum=$9
	IdLandkreis=$10
	Datenstand=$11
	NeuerFall=$12
	NeuerTodesfall=$13
	Refdatum=$14
	NeuGenesen=$15
	AnzahlGenesen=$16
	IstErkrankungsbeginn=$17
	Altersgruppe2=$18
	KreisNr[Landkreis]=IdLandkreis ## zusätzliche Ausgabe
	if(NeuerFall==0||NeuerFall==1) {
		fallbdl[Meldedatum, Bundesland]+=AnzahlFall;
		fallkrs[Meldedatum, Landkreis]+=AnzahlFall;
		fallalter[Meldedatum, Altersgruppe]+=AnzahlFall;
	}
	if(NeuerTodesfall==0||NeuerTodesfall==1) {
		todbdl[Meldedatum, Bundesland]+=AnzahlTodesfall;
		todkrs[Meldedatum, Landkreis]+=AnzahlFall;
		todalter[Meldedatum, Altersgruppe]+=AnzahlFall;
	}
	if(NeuGenesen==0||NeuGenesen==1) {
		genesenalter[Meldedatum, Altersgruppe]+=AnzahlGenesen;
	}
	datum[Meldedatum]=1
	bdl[Bundesland]=1
	krs[Landkreis]=1
	alter[Altersgruppe]=1
}
END {
	n=asorti(datum, dats);
	for(Bundesland in bdl) {
		fallcum=0;
		todcum=0;
		for(i=1;i<=n;i++) {
			Meldedatum=dats[i];
			fallcum+= fallbdl[Meldedatum, Bundesland];
		       	todcum += todbdl[Meldedatum, Bundesland];
			printf "Bundesland\t%s\t%s\t%d\t%d\t%d\t%d\n", Meldedatum, Bundesland, fallbdl[Meldedatum, Bundesland], fallcum, todbdl[Meldedatum, Bundesland], todcum;
		}
	}
	for(Landkreis in krs) {
		fallcum=0;
		todcum=0;
		fall7=0
		if(!(Landkreis in ew)) {
			printf "population of \"%s\" not found!\n", Landkreis;
		}
		for(i=1;i<=n;i++) {
			Meldedatum=dats[i];
			fallcum+= fallkrs[Meldedatum, Landkreis];
		       	todcum += todkrs[Meldedatum, Landkreis];
			fall7 += fallkrs[Meldedatum, Landkreis] - fallkrs[dats[i-7], Landkreis]
			tod7 += todkrs[Meldedatum, Landkreis] - todkrs[dats[i-7], Landkreis]
			if(ew[Landkreis]+0>0) {
				printf "Kreis\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%f\n", Meldedatum, Landkreis, fallkrs[Meldedatum, Landkreis], fallcum, todkrs[Meldedatum, Landkreis], todcum, fall7, fall7*100000.0/ew[Landkreis];
				printf "NrKrei\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%f\t%f\t%f\n", Meldedatum, KreisNr[Landkreis], Landkreis, fallkrs[Meldedatum, Landkreis], fallcum, todkrs[Meldedatum, Landkreis], todcum, fall7, tod7, ew[Landkreis], impfung[KreisNr[Landkreis]]/ew[Landkreis]*100, vollGeimpft[KreisNr[Landkreis]]/ew[Landkreis]*100; ## zusätzliche Ausgabe
			} else  {
				print "missing population for " Landkreis | "cat 1>&2"
			}
		}
	}
	for(Altersgruppe in alter) {
		fallcum=0;
		todcum=0;
		gencum=0;
		for(i=1;i<=n;i++) {
			Meldedatum=dats[i];
			fallcum+= fallalter[Meldedatum, Altersgruppe];
		       	todcum += todalter[Meldedatum, Altersgruppe];
		       	gencum += genesenalter[Meldedatum, Altersgruppe];
			printf "Alter\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n", Meldedatum, Altersgruppe, fallalter[Meldedatum, Altersgruppe], fallcum, todalter[Meldedatum, Altersgruppe], todcum, genesenalter[Meldedatum, Altersgruppe], gencum;
			if(genesenalter[Meldedatum, Altersgruppe]+todalter[Meldedatum, Altersgruppe]>0) {
				printf "AlterMort\t%s\t%s\t%d\t%d\t%d\t%d\t%.1f\n", Meldedatum, Altersgruppe, todalter[Meldedatum, Altersgruppe], todcum, genesenalter[Meldedatum, Altersgruppe], gencum, todalter[Meldedatum, Altersgruppe]*100.0/(genesenalter[Meldedatum, Altersgruppe]+todalter[Meldedatum, Altersgruppe]);
			}
		}
	}
	fallcum=0;
	todcum=0;
	gencum=0;
	for(i=1;i<=n;i++) {
		Meldedatum=dats[i];
		for(Altersgruppe in alter) {
			fallcum+= fallalter[Meldedatum, Altersgruppe];
		       	todcum += todalter[Meldedatum, Altersgruppe];
		       	gencum += genesenalter[Meldedatum, Altersgruppe];
		}
		fallday[i]=fallcum;
		todday[i]=todcum;
		genday[i]=gencum;
		if((todcum-todcumy)+(gencum-gencumy)>0) {
			printf "AllMortDay\t%s\t%d\t%d\t%d\t%d\t%.1f\n", Meldedatum, todcum-todcumy, todcum, gencum-gencumy, gencum, (todcum-todcumy)*100.0/((todcum-todcumy)+(gencum-gencumy));
		}
		if((todcum-todday[i-7])+(gencum-genday[i-7])>0) {
			printf "AllMort7Day\t%s\t%d\t%d\t%d\t%d\t%.1f\n", Meldedatum, todcum-todday[i-7], todcum, gencum-genday[i-7], gencum, (todcum-todday[i-7])*100.0/((todcum-todday[i-7])+(gencum-genday[i-7]));
		}
	}
	for(i=1;i<=n;i++) {
		Meldedatum=dats[i];
		for(Altersgruppe in alter) {
			caseday[i, Altersgruppe] = caseday[i-1, Altersgruppe] + fallalter[Meldedatum, Altersgruppe];
		       	deathday[i, Altersgruppe] = deathday[i-1, Altersgruppe] + todalter[Meldedatum, Altersgruppe];
		       	recoveredday[i, Altersgruppe] = recoveredday[i-1, Altersgruppe] + genesenalter[Meldedatum, Altersgruppe];
			#print (deathday[i, Altersgruppe]-deathday[i-7, Altersgruppe])+(recoveredday[i, Altersgruppe]-recoveredday[i-7, Altersgruppe]) | "cat 1>&2"
			printf "AgeMortDay\t%d\t%s\t%s\t%d\t%d\n", i, Meldedatum, Altersgruppe, deathday[i, Altersgruppe], recoveredday[i, Altersgruppe];
			if(((deathday[i, Altersgruppe]-deathday[i-7, Altersgruppe])+(recoveredday[i, Altersgruppe]-recoveredday[i-7, Altersgruppe]))>0) {
				printf "AgeMort7Day\t%s\t%s\t%d\t%d\t%.1f\n", Meldedatum, Altersgruppe, deathday[i, Altersgruppe]-deathday[i-7, Altersgruppe], recoveredday[i, Altersgruppe]-recoveredday[i-7, Altersgruppe], (deathday[i, Altersgruppe]-deathday[i-7, Altersgruppe])*100.0/((deathday[i, Altersgruppe]-deathday[i-7, Altersgruppe])+(recoveredday[i, Altersgruppe]-recoveredday[i-7, Altersgruppe]));
			}
			if(((deathday[i, Altersgruppe]-deathday[i-14, Altersgruppe])+(recoveredday[i, Altersgruppe]-recoveredday[i-14, Altersgruppe]))>0) {
				printf "AgeMort14Day\t%s\t%s\t%d\t%d\t%.1f\n", Meldedatum, Altersgruppe, deathday[i, Altersgruppe]-deathday[i-14, Altersgruppe], recoveredday[i, Altersgruppe]-recoveredday[i-14, Altersgruppe], (deathday[i, Altersgruppe]-deathday[i-14, Altersgruppe])*100.0/((deathday[i, Altersgruppe]-deathday[i-14, Altersgruppe])+(recoveredday[i, Altersgruppe]-recoveredday[i-14, Altersgruppe]));
			}
		}
	}
}' kreise.tsv RKI_COVID19.tsv Aktuell_Deutschland_Landkreise_COVID-19-Impfungen.tsv > de.txt
ld=`echo $lastday| sed 's/\///g;s/ .*//'`
gzip < de.txt > de.$ld.txt.gz
echo "Mortality Rate Age group 35 to 59"
egrep "^AgeMort14Day.*	A35-A59" de.txt| tail -20
echo "20 most affected Kreise"
grep "^Kreis" de.txt | grep "$lastday" | sort -t"	" -n -k9| tail -20
echo "Nürnberg last 20 days"
grep "^Kreis.*SK Nürnberg" de.txt | sort -t"	" -k2| tail -20
echo "Nürnberg Region"
egrep "^Kreis.*	(.K Nürnberg|.K Fürth|.K Erlangen|.K Ansbach|.K Amberg|.K Bamberg|.K Bayreuth|LK Weißenburg|LK Neustadt a.d.Aisch|LK Forchheim|LK Roth|LK Neumarkt|LK Kitzingen|LK Eichstätt|SK Ingolstadt|SK Schwabach)" de.txt| grep "$lastday" | sort -t"	" -n -k9
echo "Largest number of deaths"
grep "^Kreis" de.txt | grep "$lastday" | awk -F"	" '$9>0{print $0 "\t" $7/($8/$9)*10}' | sort -t"	" -n -k10|tail -20
#echo "Number of deaths of previous 7 days (Nürnberg)"
#grep '^NrKrei' de.txt | awk -F"	" '{ print $2, $4, $5, $6, $7, $8, $10/$11*1000000}' | grep 'SK Nürnberg' | sort -n | tail -50
