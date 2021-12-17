import collections
import csv
#from collections import defaultdict

limits=[35, 50, 100, 150, 200, 500, 100000]
def incidentGroup(incidents):
    i=0
    while(i<len(limits) and incidents>limits[i]):
        i+=1
    return i

serieInGroup=collections.defaultdict(dict)
badSerieInGroup=collections.defaultdict(dict)
currentGroup={} 

with open('de.txt') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter='\t')
    line_count = 0
    for row in csv_reader:
        if row[0] == "Kreis" and row[1] > "2020/01/01 00:00:00":
            county=row[2]
            incidence=float(row[8])
            print(f"County \"{county}\" has incidence {incidence}")

            #downgrading
            i=len(limits)-1
            while(i>=0 and incidence<limits[i]):
                try:
                    serieInGroup[i][county]+=1
                except KeyError:
                    serieInGroup[i][county]=1
                print(f"\tCounty {county} is in group {i} (i.e. < {limits[i]}) since {serieInGroup[i][county]} days")
                if(serieInGroup[i][county]>=5 and (not county in currentGroup or currentGroup[county]>i)):
                    currentGroup[county]=i
                    print(f"\t\tUpgrading  {row[1]}: County {county} is consistently in group {i} (i.e. < {limits[i]})")
                i-=1
            while(i>=0):
                serieInGroup[i][county]=0
                print(f"\tCounty {county} is not in group {i} (i.e. < {limits[i]}) any more")
                i-=1

            #upgrading
            i=0
            while(i<len(limits)-1 and incidence>=limits[i]):
                try:
                    badSerieInGroup[i][county]+=1
                except KeyError:
                    badSerieInGroup[i][county]=1
                print(f"\tCounty {county} is not in group {i} (i.e. < {limits[i]}) since {badSerieInGroup[i][county]} days")
                if(badSerieInGroup[i][county]>=3 and (not county in currentGroup or currentGroup[county]<=i)):
                    currentGroup[county]=i+1
                    print(f"\t\tDowngrading {row[1]}: County {county} is consistently in group {i+1} (i.e. < {limits[i+1]})")
                i+=1
            while(i<len(limits)):
                badSerieInGroup[i][county]=0
                print(f"\tCounty {county} is again in group {i} (i.e. < {limits[i]})")
                i+=1
        line_count += 1
