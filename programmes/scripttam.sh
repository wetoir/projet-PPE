#!/usr/bin/env bash

# Vérification du nombre d'arguments
if [ $# -ne 1 ]; then
    echo "Le script attend exactement un argument : fichier contenant les URLs"
    exit 1
fi

dossier_urls=$1

PROJET="/home/annabelle/projet-PPE"
DUMPS="$PROJET/dumps-text"
CONTEXTES="$PROJET/contextes"
CONCORDANCES="$PROJET/concordances"
TABLEAUX="$PROJET/tableaux"

mkdir -p "$DUMPS" "$CONTEXTES" "$CONCORDANCES" "$TABLEAUX"


# Début du fichier HTML, on utilise la boucle for pour faire un tableau par langue dans un fichier html différent $l correspond à = fr , viet..
for lang in viet tam; do
    tableau="$TABLEAUX/lang$lang.html"
lineno=1
echo "<html>
<head>
    <meta charset=\"UTF-8\">
    <title>Tableau pour $lang</title>
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
        </tr>" > "$tableau" # redirection pour obtenir les fichiers


for fichier_urls in $dossier_urls/lang$lang*.txt; do #K = oublie tout ce qu'il y a avant dans le match. \d+ = un ou plusieurs chiffre => extrait uniquement après lang-
    # il n'a rien avoir avec le for, car le for dit déjà "pour chaque fichier dans url prend le et prend également le chiffre derrière" donc i=1 sert juste pour rajouter un chiffre pour les contextes
    #baseme = extrait uniquement le nom du fichier, sans le chemin du dossier


if [ "$lang" = "viet" ]; then
    mot="hình"
elif [ "$lang" = "tam" ]; then
    mot="படம்"

fi #cette partie permet de chercher le mot écrit différement en fonction du fichier !

i=1

while read -r url; do
    echo "Traitement de $url ..." >&2

    # Récupération du code HTTP et du type MIME avec encodage
    data=$(curl -s -i -L -w "%{http_code}\n%{content_type}" -o ./temp.html "$url")
    http_code=$(echo "$data" | head -1)
    encoding=$(echo "$data" | tail -1 | grep -o "charset=[^ ;]*" | cut -d"=" -f2)

    if [ -z "$encoding" ]; then
    encoding=$(grep -i -m1 '<meta charset=' ./temp.html | sed -E 's/.*charset=["'\'']?([^"'\'' >]+).*/\1/' )
fi

    encoding=${encoding:-"N/A"}  # si encodage vide, mettre N/A

    # Conversion du HTML si besoin
    if [[ "$encoding" != "UTF-8" && "$encoding" != "N/A" ]]; then
        iconv -f "$encoding" -t UTF-8 ./temp.html -o ./temp_utf8.html
        mv ./temp_utf8.html ./temp.html
        encoding="UTF-8"
    fi

    # Dump textuel avec lynx
    dump_file="$DUMPS/lang$lang-$i.txt" #verifier que le chemin est bon
    lynx -dump -nolist ./temp.html > "$dump_file"

    if [ "$lang" = "viet" ]; then
        python3 programmes/script-tokenize_vietnamien.py "$dump_file" > "$dump_file.tmp"
        mv "$dump_file.tmp" "$dump_file"
    fi

    # Nombre de mots
    nb_mots=$(wc -w < "$dump_file")

    # Occurrences du mot ciblé "image"
    occurrences=$(grep -i -o "$mot" "$dump_file" | wc -w)

    echo "$i $lang"
    # Extraction du contexte (2 lignes avant et après) /home/annabelle/projet-PPE/contextes

    contexte_file="$CONTEXTES/lang$lang-$i.txt"  #le $lang correspond tout simplement à la variable crée plus haut qui récupère le chiffre après lang-
    grep -B2 -A2 -i "$mot" "$dump_file" > "$contexte_file"

    # Concordance gauche/droite pour chaque occurence
    concordance_file="$CONCORDANCES/lang$lang-$i.html"
    echo "<html><body><table border='1'><tr><th>Gauche</th><th>Mot</th><th>Droite</th></tr>" > "$concordance_file"
    while read -r line_context; do
        gauche=$(echo "$line_context" | sed 's/\(.*\)\$mot\b.*/\1/')
        droite=$(echo "$line_context" | sed 's/.*\$mot\b\(.*\)/\1/')
        echo "<tr><td>$gauche</td><td>$mot</td><td>$droite</td></tr>" >> "$concordance_file"
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
        </tr>" >> "$tableau"

    i=$((i+1))
    lineno=$((lineno+1))
done < "$fichier_urls"

done


# Fermeture de la table et du HTML
echo "    </table>
</body>
</html>" >> "$tableau"
done

# Nettoyage temporaire
rm -f ./temp.html


