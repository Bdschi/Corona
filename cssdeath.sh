#!/bin/bash

dir=/mnt/c/Doc/COVID-19/csse_covid_19_data/csse_covid_19_daily_reports
( cd $dir; git pull) 

now=`date +"%s"`
yesterday=`expr $now - 24 \* 3600`
lweek=`expr $now - 8 \* 24 \* 3600`
yesterday=`date +"%02m-%02d-%4Y" -d "@$yesterday"`
file=$dir/$yesterday.csv
lweek=`date +"%02m-%02d-%4Y" -d "@$lweek"`
filew=$dir/$lweek.csv
ls -l $file $filew
awk -F"	" '{
	for(i=1;i<=NF;i++) {
		sub("^\"","",$i); 
		sub("\"$","",$i); 
	}
	if(FNR>1) {
		FIPS=$1
		Admin2=$2
		Province_State=$3
		Country_Region=$4
		Last_Update=$5
		Lat=$6
		Long=$7
		Confirmed=$8
		Deaths=$9
		Recovered=$10
		Active=$11
		Combined_Key=$12
		Incidence_Rate=$13
		Case_Fatality_Ratio=$14
		#printf("Country=\"%s\" Province=\"%s\" Confirmed=%d Incidence_Rate=%.2f Case_Fatality_Ratio=%.2f key=\"%s\"\n", Country_Region, Province_State, Confirmed, Incidence_Rate, Case_Fatality_Ratio, Combined_Key);
		if(NR==FNR) {
			if(Province_State!="") {
				cyp[Country_Region "/" Province_State]+=Deaths
				if(Incidence_Rate+0>0) {
					pyp[Country_Region "/" Province_State]+=Confirmed/Incidence_Rate*100000;
				}
			}
			cy[Country_Region]+=Deaths
			if(Incidence_Rate+0>0) {
				py[Country_Region]+=Confirmed/Incidence_Rate*100000;
			}
		} else {
			if(Province_State!="") {
				clp[Country_Region "/" Province_State]+=Deaths
				if(Incidence_Rate+0>0) {
					plp[Country_Region "/" Province_State]+=Confirmed/Incidence_Rate*100000;
				}
			}
			cl[Country_Region]+=Deaths
			if(Incidence_Rate+0>0) {
				pl[Country_Region]+=Confirmed/Incidence_Rate*100000;
			}
		}
	}

}
END {
	for(Province in cyp) {
		if(pyp[Province]>0 && plp[Province]>0) {
			pop=(pyp[Province]+plp[Province])/2
			printf "%.2f,%s,%d,%d,%d,%d\n", (cyp[Province]-clp[Province])*1000000.0/pop, Province, cyp[Province], pyp[Province], clp[Province], plp[Province];
		}
	}
	for(Country in cy) {
		if(py[Country]>0 && pl[Country]>0) {
			pop=(py[Country]+pl[Country])/2
			printf "%.2f,%s,%d,%d,%d,%d\n", (cy[Country]-cl[Country])*1000000.0/pop, Country, cy[Country], py[Country], cl[Country], pl[Country];
		}
	}
}' <( ./csv2tsv.py < $file) <( ./csv2tsv.py < $filew) | sort -n | gzip > cssoutdeaths.`date +"%Y%m%d"`.txt.gz
