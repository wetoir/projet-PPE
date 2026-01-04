#!/usr/bin/env bash

if [ $# -ne 1 ]
then
	echo "Le script attend exactement un argument"
	exit 1
fi

fichier_urls=$1
TAB="../tableaux/vi-tableau.html"
ASPIRATION="../aspi"
DUMP="../dumps"
LANG=Viet
MOT="hình ảnh"

cat > "$TAB" <<EOF
<html>
	<head>
		<meta charset="UTF-8">
		<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css" />
    	<meta name="viewport" content="width=device-width, initial-scale=1">
		<title>Tableau Viet – PPE 2025</title>
	</head>

	<!-- BarreDeNavi -->
		<nav class="tabs is-centered mb-0">
        	<ul>
        		<li><a href="../../index.html">Accueil</a></li>
            	<li class="is-active"><a href="tableau-fr.html">Tableaux</a></li>
			</ul>
    	</nav>
		<!-- Bannière/Hero -->
		<section class="hero is-warning is-small">
			<div class="hero-body">
				<p class="title">Résultats de la collecte</p>
				<p class="subtitle">Tableau généré automatiquement à partir du fichier TSV</p>
			</div>
		</section>
		<!-- ContenuPrincipal -->
		<section class="section">
			<div class="card">
				<p class="card-header-title">Tableau des sites analysés</p>
				<div class="card-content">
					<div class="table-container"> <!-- mettre dans un div sinon table n'est pas flexible par rapport à la taille de l'écran -->
						<table class="table is-bordered is-striped is-hoverable is-fullwidth">
							<tr>
								<th>Numéro</th>
								<th>URL</th>
								<th>Code</th>
								<th>Encodage</th>
								<th>Nombre d'occurences</th>
                                <th>HTLM</th>
                                <th>Dump</th>
                                <th>Concordoncier</th> 
							</tr>
EOF

lineno=1    #numéro
while read -r line
do
    aspi_file="$ASPIRATION/lang${LANG}_$lineno.html"	# chemin vers le fichier html à créer
    aspi=$(curl -siL -w "%{http_code}\n%{content_type}" -o "$aspi_file" $line)	# aspiration du site
    http_code=$(echo "$aspi" | head -1)	# réponse du site
	encoding=$(echo "$aspi" | tail -1 | grep -Po "charset=\S+" | cut -d"=" -f2)	# encodage du site

    # if [ -z "${encoding}" ] # true si length de encoding est 0, donc pas de détails sur l'encodage du site
	# then
	# 	encoding="N/A" # petit raccourci qu'on peut utiliser à la place du if : encoding=${encoding:-"N/A"}
	# fi

    # nbmots=$(cat ./.data.tmp | lynx -dump -nolist -stdin | wc -w)
    dump_file="$DUMP/lang${LANG}_$lineno.txt" 
	if [[ "$encoding" == "UTF-8" || "$encoding" == "utf-8" ]]	# si le site est en utf-8
	then
		dump=$(lynx -dump -nolist "$aspi_file" > "$dump_file")	# on extrait le texte brut
	else	# sinon
		encode=$(file "$aspi_file" | cut -d"," -f2 | cut -d" " -f2)
		VERIFENCODAGEDANSICONV=$(iconv -l | egrep -io "$encode" | sort -u)	# on va voir si l'encodage détecté par file est reconnu par iconv
		if [[ $VERIFENCODAGEDANSICONV != "" && $VERIFENCODAGEDANSICONV != "Unicode" ]]	# si oui alors on va convertir le fichier aspiré en utf-8 et extraire le texte brut
		then
			iconv -f "$encoding" -t UTF-8 "$aspi_file" -o "$aspi_file.utf8"
			mv "$aspi_file.utf8" "$aspi_file"
			encoding="UTF-8"	
			dump=$(lynx -dump -nolist "$aspi_file" > "$dump_file")
		else	# sinon alors on va laisser son encodage inconnu et essaie quand même d'extraire le texte brut
			encoding="N/A"
			dump=$(lynx -dump -nolist "$aspi_file" > "$dump_file")
		fi
    fi
    
    nbOcc=$(grep -Fic "$MOT" "$dump_file")
    concor="N/A"

	echo -e "							<tr>
								<td>$lineno</td>
								<td>$line</td>
								<td>$http_code</td>
								<td>$encoding</td>
								<td>$nbOcc</td>
                                <td><a href="$aspi_file">HTML</a></td>
                                <td><a href="$dump_file">Dump</a></td>
                                <td>$concor</td>
							</tr>" >> "$TAB"

	lineno=$(expr $lineno + 1)
done < $fichier_urls

echo "						</table>
					</div>
				</div>
			</div>
		</section>
	</body>
</html>" >> "$TAB"


