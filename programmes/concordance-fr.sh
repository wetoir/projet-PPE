#!/usr/bin/bash

CHEM_CONTEXT=$1
CHEM_CONCORDANCE=$2

if [ $# -ne 2 ]
then
        echo "Le script doit prendre exactement 2 arguments."
         exit 1

fi

#pour chaque fichier dans le dossier contexte commençant par langfr-numéro.html (on précise car il y a plsuieurs fichiers notamment tamoul, vietnamien)
for fichier in "$CHEM_CONTEXT"/langfr-*.txt
do
    nom_fichier=$(basename "$fichier" .txt)
    #basename va prendre le chemin entier, on l'utilsier car on veut qu'il ne prenne que le nom du fichier pour créer le fichier html.
    fichier_html_concordance="$CHEM_CONCORDANCE/$nom_fichier.html"

echo -e "<html>
            <head>
                <meta charset=\"UTF-8\">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css">
            </head>
            <body>
               <table class="table is-bordered is-striped is-narrow is-hoverable is-fullwidth">
                    <tr>
                        <th>Contexte gauche</th>
                        <th>Mot cible</th>
                        <th>Contexte droit</th>

                    </tr>" > "$fichier_html_concordance"

        grep -o -i -E '.{0,50}\bimage?\b.{0,50}' "$fichier" | while IFS= read -r line
    do
        mot=$(echo "$line" | grep -o -i -E "\bimage?\b" | head -1)

        contexte_gauche=$(echo "$line" | sed -E "s/^(.*)\bimage?\b.*$/\1/I")

        contexte_droit=$(echo "$line" | sed -E "s/^.*\bimage?\b(.*)$/\1/I")
    # la commande sed pour remplacer toutes les occurrences de “moulins à vent" par moulins-à-vent (en utilisant un argument ’s/.../.../’) = on réccupère ce qui se trouve autour du mot image (les contextes)

        echo -e "  <tr>
                    <td>$contexte_gauche</td>
                    <td>$mot</td>
                    <td>$contexte_droit</td>
                   </tr>" >> "$fichier_html_concordance"

    done

    echo -e "          </table>
                </body>
            </html>" >> "$fichier_html_concordance"

done

#faire exécuter avec : ./concordance-fr.sh ../contextes ../concordances

