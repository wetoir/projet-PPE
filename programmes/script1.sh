#!/usr/bin/env bash

# Vérification du nombre d'arguments
if [ $# -ne 1 ]; then
    echo "Le script attend exactement un argument : fichier contenant les URLs"
    exit 1
fi

dossier_urls=$1

# Début du fichier HTML
echo "<html>
<head>
    <meta charset=\"UTF-8\">
    <title>Tableau avec concordance</title>
    <style>
        table { border-collapse: collapse; width: 90%; margin: auto; }
        th, td { border: 1px solid black; padding: 8px; text-align: center; }
        th { background-color: #ddd; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2 style='text-align:center;'>Tableau pour 'image'</h2>
    <table>
        <tr>
            <th>Numero</th>
            <th>URL</th>
            <th>Code HTTP</th>
            <th>Encodage</th>
            <th>Nombre de mots</th>
            <th>Occurrences</th>
            <th>Dump textuel</th>
            <th>Contexte</th>
            <th>Concordance</th>
        </tr>"

lineno=1

for fichier_urls in "$dossier_urls"/lang-*.txt; do  #verifier si mon chemin est exact.
    lang=$(basename "$fichier_urls" | grep -oP "lang-\K\d+") #K = oublie tout ce qu'il y a avant dans le match. \d+ = un ou plusieurs chiffre => extrait uniquement après lang-
    i=1 # il n'a rien avoir avec le for, car le for dit déjà "pour chaque fichier dans url prend le et prend également le chiffre derrière" donc i=1 sert juste pour rajouter un chiffre pour les contextes
    #baseme = extrait uniquement le nom du fichier, sans le chemin du dossier

while read -r url; do
    echo "Traitement de $url ..." >&2

    # Récupération du code HTTP et du type MIME avec encodage
    data=$(curl -s -i -L -w "%{http_code}\n%{content_type}" -o ./temp.html "$url")
    http_code=$(echo "$data" | head -1)
    encoding=$(echo "$data" | tail -1 | grep -Po "charset=\S+" | cut -d"=" -f2)
    encoding=${encoding:-"N/A"}  # si encodage vide, mettre N/A

    # Conversion du HTML si besoin
    if [[ "$encoding" != "UTF-8" && "$encoding" != "N/A" ]]; then
        iconv -f "$encoding" -t UTF-8 ./temp.html -o ./temp_utf8.html
        mv ./temp_utf8.html ./temp.html
        encoding="UTF-8"
    fi

    # Dump textuel avec lynx
    dump_file="./dump/lang-$lang-$i.txt" #verifier que le chemin est bon
    lynx -dump -nolist ./temp.html > "$dump_file"

    # Nombre de mots
    nb_mots=$(wc -w < "$dump_file")

    # Occurrences du mot ciblé "image"
    occurrences=$(grep -i -o "image" "$dump_file" | wc -w)

    # Extraction du contexte (2 lignes avant et après)
    contexte_file="./contextes/lang-$lang-$i.txt"  #le $lang correspond tout simplement à la variable crée plus haut qui récupère le chiffre après lang-
    grep -B2 -A2 -i "image" "$dump_file" > "$contexte_file"

    # Concordance gauche/droite pour chaque occurence
    concordance_file="./concordance/$lang-$i.html"
    echo "<html><body><table border='1'><tr><th>Gauche</th><th>Mot</th><th>Droite</th></tr>" > "$concordance_file"
    while read -r line_context; do
        gauche=$(echo "$line_context" | sed 's/\(.*\)\bimage\b.*/\1/')
        droite=$(echo "$line_context" | sed 's/.*\bimage\b\(.*\)/\1/' | sed 's/[^a-zA-Z ]//g')
        echo "<tr><td>$gauche</td><td>image</td><td>$droite</td></tr>" >> "$concordance_file"
    done < "$contexte_file"
    echo "</table></body></html>" >> "$concordance_file"

    # Ajout de la ligne dans le tableau HTML principal
    echo "        <tr>
            <td>$lineno</td>
            <td><a href='$url'>$url</a></td>
            <td>$http_code</td>
            <td>$encoding</td>
            <td>$nb_mots</td>
            <td>$occurrences</td>
            <td><a href='$dump_file'>dump</a></td>
            <td><a href='$contexte_file'>contexte</a></td>
            <td><a href='$concordance_file'>concordance</a></td>
        </tr>"

    i=$((i+1))
    lineno=$((lineno+1))
done < "$fichier_urls"

# Fermeture de la table et du HTML
echo "    </table>
</body>
</html>"

# Nettoyage temporaire
rm -f ./temp.html


