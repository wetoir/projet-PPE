#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage : $0 <dossier_urls>"
    exit 1
fi

dossier_urls=$1

PROJET="/home/annabelle/projet-PPE"
ROBOTS="$PROJET/robots"
BLACKLISTS="$ROBOTS/blacklists"

mkdir -p "$ROBOTS" "$BLACKLISTS"

lang="tam"

# Pour chaque fichier d'URLs tamoul
for fichier_urls in "$dossier_urls"/lang${lang}*.txt; do
    echo "Traitement de $fichier_urls ..."

    blacklist_file="$BLACKLISTS/$(basename "$fichier_urls")-blacklist"
    > "$blacklist_file"  # vide le fichier avant écriture

    # Table associative pour stocker les robots.txt déjà téléchargés par serveur
    declare -A SERVEURS_ROBOTS

    i=1
    while read -r url; do
        # Extraire le serveur (ex: https://monsite.fr)
        serveur=$(echo "$url" | awk -F/ '{print $1 "//" $3}')

        # Fichier robots pour cette URL
        robots_file="$ROBOTS/robots-${lang}-${i}.txt"

        # Télécharger robots.txt seulement si on ne l'a pas déjà fait pour ce serveur
        if [[ -z "${SERVEURS_ROBOTS[$serveur]}" ]]; then
            curl -s --fail "$serveur/robots.txt" -o "$robots_file"
            # Marquer ce serveur comme traité
            SERVEURS_ROBOTS[$serveur]="$robots_file"
        else
            robots_file="${SERVEURS_ROBOTS[$serveur]}"
            # Copier le robots.txt existant dans le fichier spécifique de l'URL
            cp "$robots_file" "$ROBOTS/robots-${lang}-${i}.txt"
            robots_file="$ROBOTS/robots-${lang}-${i}.txt"
        fi

        # Analyse du robots.txt
        autorisation="OUI"  # par défaut
        user_agent_ok="false"

        if [[ -s "$robots_file" ]]; then
            autorisation="OUI"  # robots.txt existe, mais on n'a pas encore trouvé d'interdiction
            while IFS= read -r ligne; do
                ligne=$(echo "$ligne" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

                # Détecter User-Agent: *
                if [[ "$ligne" =~ ^User-Agent:[[:space:]]*\*$ ]]; then
                    user_agent_ok="true"
                    continue
                fi

                # Détecter un autre User-Agent
                if [[ "$ligne" =~ ^User-Agent: ]] && [[ ! "$ligne" =~ ^User-Agent:[[:space:]]*\*$ ]]; then
                    user_agent_ok="false"
                    continue
                fi

                # Si User-Agent: * actif et ligne Disallow
                if [[ "$user_agent_ok" == "true" ]] && [[ "$ligne" =~ ^Disallow:[[:space:]]*(.*) ]]; then
                    chemin_interdit="${BASH_REMATCH[1]}"
                    if [[ -n "$chemin_interdit" ]] && [[ "$url" == "$serveur$chemin_interdit"* ]]; then
                        autorisation="NON"
                        break
                    fi
                fi
            done < "$robots_file"
        fi

        # Écrire dans la blacklist
        echo "$url $autorisation" >> "$blacklist_file"

        i=$((i+1))
    done < "$fichier_urls"

    # Libérer la table associative pour le fichier suivant
    unset SERVEURS_ROBOTS
done

echo "Blacklists terminées pour tous les fichiers tamoul."
