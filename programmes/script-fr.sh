#!/usr/bin/bash

if [ $# -ne 3 ]
then
	echo "Le script attend exactement un argument"
	exit 1
fi

FICHIER_URLS=$1
FICHIER_TSV=$2
FICHIER_HTML=$3

lineno=1

echo "<html>
	<head>
		<meta charset=\"UTF-8\">
	</head>

	<body>
	  <h1>Tableau des URLS pour la langue française</h1>
		<table>
			<tr>
				<th>numero</th>
				<th>URL</th>
				<th>code</th>
				<th>encodage</th>
				<th>nombre de mots</th>
			</tr>" >> "$FICHIER_HTML"

while read -r line
do
	data=$(curl -s -i -L -w "%{http_code}\n%{content_type}" -o /dev/null "$line")
	http_code=$(echo "$data" | head -1)
	encoding=$(echo "$data" | tail -1 | grep -Po "charset=\S+" | cut -d"=" -f2)

	if [ -z "${encoding}" ]
	then
		encoding="N/A"
    fi
	nbmots=$(curl -s -L "$line" | wc -w)

	echo -e "
            <tr>
				<td>$lineno</td>
				<td>$line</td>
				<td>$http_code</td>
				<td>$encoding</td>
				<td>$nbmots</td>
			</tr>" >> "$FICHIER_HTML"

	lineno=$(expr $lineno + 1)

echo -e "$lineno\t$line\t$http_code\t$encoding\t$nbmots" >> "$FICHIER_TSV"

done < "$FICHIER_URLS"

echo -e "</table>
	</body>
</html>" >> "$FICHIER_HTML"

#excécuter avec : ./script-fr.sh ../URLs/langfr.txt ../tableaux/langfr.tsv ../tableaux/langfr.html

