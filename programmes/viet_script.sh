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
    aspi_file="$ASPIRATION/lang${LANG}_$lineno.html" 
    aspi=$(curl -siL -w "%{http_code}\n%{content_type}" -o "$aspi_file" $line)
    http_code=$(echo "$aspi" | head -1)
	encoding=$(echo "$aspi" | tail -1 | grep -Po "charset=\S+" | cut -d"=" -f2)

    if [ -z "${encoding}" ] # true if length of encoding est 0
	then
		encoding="N/A" # petit raccourci qu'on peut utiliser à la place du if : encoding=${encoding:-"N/A"}
	fi

    # nbmots=$(cat ./.data.tmp | lynx -dump -nolist -stdin | wc -w)
    dump_file="$DUMP/lang${LANG}_$lineno.txt" 
    dump=$(lynx -dump -nolist "$aspi_file" > "$dump_file")
    nbOcc=$(cat "$dump_file" | grep -ic $MOT)
    concor=$()

	echo -e "							<tr>
								<td>$lineno</td>
								<td>$line</td>
								<td>$http_code</td>
								<td>$encoding</td>
								<td>$nbOcc</td>
                                <td>$aspi_file</td>
                                <td>$dump</td>
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


