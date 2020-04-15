#!/usr/bin/env bash

# Looks to see if folder is made, if not, makes it
if [ ! -d Phlashko-Country-IP-Count-And-List ]
	then
		mkdir "Phlashko-Country-IP-Count-And-List"
fi

# This checks to see if the argument is entered, is a pcap, and exists
if [ -z "$1" ] || [[ ! $1 == *.pcap ]]
	then
		echo -e '\n () ()\n(  >_<) ~ Bad format.  Your syntax should look like Country-IP-Count-And-List.sh PcapFile.pcap IPv4ip\n("")("")\n'
		exit
fi

# This checks to make sure the pcap is in the file with the script
if [ ! -f $1 ]
	then
		echo -e '\n () ()\n(  >_<) ~ File does not exist.  Is the pcap in the same folder as the ip-geo-checker.sh script?\n("")("")\n'
		exit
fi

# This checks to see results will be overwritten
if [ -f Phlashko-Country-IP-Count-And-List/results.txt ] || [[ -f Phlashko-Country-IP-Count-And-List/results.csv ]]
	then
		echo -e '\n () ()\n(  >_<) ~ Results already exist.  Delete, move, or rename past results file(s) located in Phlashko-Country-IP-Count-And-List to continue.\n("")("")\n'
		exit
fi

# This looks up the pcap information
tshark -r $1 -Y "ip.dst == $2" | awk '{print $3}' | sort > ipdest.txt

# This does the Destination GeoIP lookup against the GeoIP.dat
cat ipdest.txt | while read line 
			do
				geo=$(geoiplookup -f /usr/share/GeoIP/GeoIP.dat $line | awk '{print substr($0, index($0,$5))}' | sed 's/Korea, Republic of/Korea/g')
				echo "$geo $line " >> ipinfo.txt			
			done

# This checks to see results will be overwritten
if [ ! -f ipinfo.txt ] 
	then
		echo -e '\n () ()\n(  >_<) ~ IP did not exist in PCAP.  Make sure your using a valid destination ip from pcap.\n("")("")\n';
		rm ipdest.txt
		exit
fi

# sorts geo results by country
sort -k 1 ipinfo.txt >> sortedip.txt

# takes out duplicate IPs
cat sortedip.txt | uniq | awk '{print $1}' >> sortedip2.txt

# throws ip into a line under single country
awk '$1 != prev {if (NR != 1) print prev; prev=$1; delete a};
!($2 in a){a[$2]; printf "%s ", $2};' sortedip.txt >> combine.txt

# removes weird error that sometimes adds country again
sed 's/[A-Za-z]*//g' combine.txt >> combine1.txt

# counts results
uniq -c sortedip2.txt >> sortedip3.txt

# pasts counts and country names together
paste -d" " sortedip3.txt combine1.txt >> sortedip4.txt

# adds blank lines between txt file
sed -e 'G' sortedip4.txt >> Phlashko-Country-IP-Count-And-List/results.txt

# converts txt to csv
tr -s ' ' ',' < Phlashko-Country-IP-Count-And-List/results.txt >> combine.csv

# fixes wierd error that adds random blank column
cut -d"," -f2- combine.csv >> combine1.csv

# adds headers to results.csv
{ echo 'UNIQ IP COUNT, COUNTRY, IPS'; cat combine1.csv; } > Phlashko-Country-IP-Count-And-List/results.csv

# announces script ran
echo -e '\n'$(pwd)'/Phlashko-Country-IP-Count-And-List/results.csv to be opened in an EXCEL like program.\n\n'$(pwd)'/Phlashko-Country-IP-Count-And-List/results.txt is the terminal quick text view\n'

# removes temp files
rm combine* 2> /dev/null
rm sortedi* 2> /dev/null
rm ip* 2> /dev/null
rm convert.csv 2> /dev/null
