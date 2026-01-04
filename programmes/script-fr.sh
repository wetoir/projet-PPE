#!/usr/bin/bash

if [ $# -ne 6 ]
then
	echo "Le script attend exactement 6 arguments"
	exit 1
fi

#On met en variable les chemins attendus
CHEM_FICHIER_URLS=$1
CHEM_FICHIER_TSV=$2
CHEM_FICHIER_HTML=$3
CHEM_ASPIRATION=$4
CHEM_DUMP=$5
CHEM_CONTEXTE=$6

lineno=1

#https://bulma.io/documentation/start/overview/
echo "<!DOCTYPE html>
<html>
	<head>
		<meta charset=\"UTF-8\">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css">
	</head>
	<body>
	  <h1>Tableau des URLS pour la langue française</h1>
		<style>
			 h1{
				color: hsl(217, 71%, 53%);
				font-size: 2.5rem;
				}
		</style>
		<table class="table is-bordered is-striped is-narrow is-hoverable is-fullwidth">
			<tr>
				<th>Numero</th>
				<th>URL</th>
				<th>Code</th>
				<th>Encodage</th>
				<th>Nombre de mots</th>
				<th>Aspirations</th>
				<th>Dumps</th>
				<th>Compte</th>
				<th>Contexte</th>
			</tr>

			<style>
			 h1{
				color: hsl(217, 71%, 53%);
				font-size: 2.5rem;
				}
		</style>" >> "$CHEM_FICHIER_HTML"

while read -r line
do
	data=$(curl -s -i -L -w "%{http_code}\n%{content_type}" -o /dev/null "$line")
	http_code=$(echo "$data" | head -1)
	encoding=$(echo "$data" | tail -1 | grep -Po "charset=\S+" | cut -d"=" -f2)

	chemin_sortie_aspiration="$CHEM_ASPIRATION/langfr-$lineno.html"
		aspiration=$(curl -s -L "$line" -o "$chemin_sortie_aspiration")
		#-o <fichier> : indique un <fichier> de sortie
		#-L : suit les redirections
		#-s silent

	chemin_sortie_dump="$CHEM_DUMP/langfr-$lineno.txt"
		dump=$(lynx -dump -nolist "$chemin_sortie_aspiration" > "$chemin_sortie_dump")
		#récupérer le contenu textuel d’une page pour l’afficher (sans navigation) et retirer la liste des liens d’une page à l’affichage


	compte_nb_mot=$(egrep -i -o "\bimage\b" "$chemin_sortie_dump" | wc -l)
	#cf bi-projetc.pdf : egrep pour les ER car on cherche combien de fois le nombre d’occurrences qu'on cherche "image" apparait sur chaque page. Quelque soit la taille du mot/lettre.


	contexte_fichier_sortie="$CHEM_CONTEXTE/langfr-$lineno.txt"
	contexte=$(grep -C 2 '\bimage\b' "$chemin_sortie_dump" > "$contexte_fichier_sortie")
	# si on peut utilsier les ER avec \bimage\b on peut lui faire dire de capturer n'importe quel mots/suites de caractères avec/séparé par un espace. on en prend jusqu'à 10.


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
				<td><a href="$chemin_sortie_aspiration">Aspiration</a></td>
				<td><a href="$chemin_sortie_dump">Dump</a></td>
				<td>$compte_nb_mot</td>
				<td><a href="$contexte_fichier_sortie">Contexte</a></td>
			</tr>" >> "$CHEM_FICHIER_HTML"

	lineno=$(expr $lineno + 1)

echo -e "$lineno\t$line\t$http_code\t$encoding\t$nbmots\t$chemin_sortie_aspiration\t$chemin_sortie_dump\t$compte_nb_mot\t$contexte" >> "$CHEM_FICHIER_TSV"

done < "$CHEM_FICHIER_URLS"

echo -e "</table>
	</body>
</html>" >> "$CHEM_FICHIER_HTML"

#excécuter avec : ./scipt-fr.sh ../URLs/langfr.txt ../tableaux/langfr.tsv ../tableaux/langfr.html ../aspirations ../dumps-text ../contextes

