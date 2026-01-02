#!/usr/bin/env bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8


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
ASPIRATIONS="$PROJET/aspirations"
TABLEAUX="$PROJET/tableaux"

mkdir -p "$DUMPS" "$CONTEXTES" "$CONCORDANCES" "$TABLEAUX" "$ASPIRATIONS"


# Début du fichier HTML, on précise qu'on veut que le tamoul
lang="tam"
mot="படம்"
tableau="$TABLEAUX/lang${lang}.html"
lineno=1

echo "<html>
<head>
    <meta charset=\"UTF-8\">
    <title>Tableau pour le TAMOUL</title>
    <style>
        table { border-collapse: collapse; width: 90%; margin: auto; }
        th, td { border: 1px solid black; padding: 8px; text-align: center; }
        th { background-color: #ddd; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2 style='text-align:center;'>Tableau pour 'image' en TAMOUL </h2>
    <table>
        <tr>
            <th>Numero</th>
            <th>URL</th>
            <th>Code HTTP</th>
            <th>Encodage</th>
            <th>Aspirations</th>
            <th>Nombre de mots</th>
            <th>Occurrences</th>
            <th>Dump textuel</th>
            <th>Contexte</th>
            <th>Concordance</th>
        </tr>" > "$tableau" # redirection pour obtenir les fichiers

i=1

for fichier_urls in $dossier_urls/lang${lang}*.txt; do #K = oublie tout ce qu'il y a avant dans le match. \d+ = un ou plusieurs chiffre => extrait uniquement après lang-
    # il n'a rien avoir avec le for, car le for dit déjà "pour chaque fichier dans url prend le et prend également le chiffre derrière" donc i=1 sert juste pour rajouter un chiffre pour les contextes
    #baseme = extrait uniquement le nom du fichier, sans le chemin du dossier

while read -r url; do
    echo "Traitement de $url ..." >&2

    aspiration_file="$ASPIRATIONS/lang${lang}-$i.html"
    # Récupération du code HTTP et du type MIME avec encodage
    data=$(curl -s -L -w "%{http_code}\n%{content_type}" -o "$aspiration_file" "$url")


    http_code=$(echo "$data" | head -1)
    encoding=$(echo "$data" | tail -1 | grep -o "charset=[^ ;]*" | cut -d"=" -f2)

    if [ -z "$encoding" ]; then
    encoding=$(grep -i -m1 '<meta charset=' "$aspiration_file" | sed -E 's/.*charset=["'\'']?([^"'\'' >]+).*/\1/' )
    fi

    encoding=${encoding:-"N/A"}  # si encodage vide, mettre N/A

    # Conversion du HTML si besoin
    if [[ "$encoding" != "UTF-8" && "$encoding" != "N/A" ]]; then
        iconv -f "$encoding" -t UTF-8 "$aspiration_file" -o "$aspiration_file.utf8"
        mv "$aspiration_file.utf8" "$aspiration_file"
        encoding="UTF-8"
    fi

    # Dump textuel avec lynx
    dump_file="$DUMPS/lang$lang-$i.txt" #verifier que le chemin est bon
    lynx -dump -nolist "$aspiration_file" > "$dump_file"


    # Nombre de mots
    nb_mots=$(wc -w < "$dump_file")

    # Occurrences du mot ciblé "image"
    occurrences=$(grep -i -o "$mot" "$dump_file" | wc -w)

    echo "$i $lang" # pour suivre l'exécution
    # Extraction du contexte (2 lignes avant et après) /home/annabelle/projet-PPE/contextes

    contexte_file="$CONTEXTES/lang${lang}-$i.txt"  #le $lang correspond tout simplement à la variable crée plus haut qui récupère le chiffre après lang-
    grep -B2 -A2 -i "$mot" "$dump_file" > "$contexte_file"

    # Concordance gauche/droite pour chaque occurence
    concordance_file="$CONCORDANCES/lang${lang}-$i.html"
    echo "<html><body><table border='1'><tr><th>Gauche</th><th>Mot</th><th>Droite</th></tr>" > "$concordance_file"
    while read -r line_context; do
        gauche=$(echo "$line_context" | sed "s/\(.*\)$mot.*/\1/")
        droite=$(echo "$line_context" | sed "s/.*$mot\(.*\)/\1/")
        echo "<tr><td>$gauche</td><td>$mot</td><td>$droite</td></tr>" >> "$concordance_file"
    done < "$contexte_file"
    echo "</table></body></html>" >> "$concordance_file"

    # Ajout de la ligne dans le tableau HTML principal
    echo "        <tr>
            <td>$lineno</td>
            <td><a href='$url'>$url</a></td>
            <td>$http_code</td>
            <td>$encoding</td>
            <td><a href='$aspiration_file'>html</a></td>
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

# awk = chaque mot sur une ligne mais fonctionne pas avec dumps
# + ligne vide ajouté après une ponctuation forte

output_file="$CONTEXTES/concatenation_contextes-${lang}.txt"
> "$output_file"  # vide le fichier avant d'écrire

for file in "$CONTEXTES"/lang${lang}-*.txt; do
    awk '{
        for(i=1;i<=NF;i++){
            word=$i
            print word
            if(word ~ /[.!?]$/) print ""
        }
    }' "$file" >> "$output_file"
    echo "" >> "$output_file"  # saut de ligne entre fichiers
done

output_dumps="$DUMPS/concatenation_dumps-${lang}.txt"
> "$output_dumps"

for file in "$DUMPS"/lang${lang}-*.txt; do
    awk '{
        for(i=1;i<=NF;i++){
            word=$i
            print word
            if(word ~ /[.!?]$/) print ""
        }
    }' "$file" >> "$output_dumps"
    echo "" >> "$output_dumps"  # saut de ligne entre fichiers
done




