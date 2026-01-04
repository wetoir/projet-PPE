import os
#Le module os contient toute une série de fonctions pr dialoguer avec le système d’exploitation (operating system)
from wordcloud import WordCloud
import matplotlib.pyplot as plt
from nltk.corpus import stopwords
import nltk
#bibliothèque Python open-source et contient des corpus et outils principalement pour l’anglais, mais certaines ressources sont disponibles pour d’autres langues.
#nltk utile pour les stopwords, pour en extraire des mots moins importants

# obtenir les stopwords français :
try:
    stopwords_fr = set(stopwords.words('french'))
except:
    nltk.download('stopwords')
    stopwords_fr = set(stopwords.words('french'))

# ajouts des stopwords en plus :
mots_ignorer = {'un', 'une', 'd', 'l', 'quelques', 'fichier', 'cette', 'ces', 'tout', 'tous', 'afin', 'mot', 'peut', 'autant', 'comporte', 'décallée', 'doit', 'apparu', 'voir', 'auprès', 'dite', 'deuxième', 'quelle', 'première', 'chaque', 'toute', 'vaut', '.', 'bonne', 'autre', 'non', 'fournit', 'sipi', 'plus', 'selon', 'utilisé', 'courant', 'comme', 'comment', 'troisième', 'très', 'existe', 'detectors', 'désignait', 'oppose', 'prévue', 'correspond', 'fermer', 'véritablement', 'également', 'devient', 'sous', 'aussi', 'parfaitement', 'compréhension', 'complètement', 'appelle'}
stopwords_fr.update(mots_ignorer)

#sur git-along, sur un terminal, on regroupe tous les contextes fr ensemble : en étant dans l'environnement virtuel, on se place avec cd dans le dossier contextes et on fait la commande " cat langfr-*.txt > tous_contextesfr.txt", ensuite on aura un fichier toux_contexte qui a regroupé tous les textes des contextes ensemble. on déplace le fichier dans le dossier programmes.

fichier = "tous_contextesfr.txt"
with open(fichier, 'r', encoding='utf-8') as f:
    texte = f.read().lower()
#on ouvre un le fichier qui contient tous les contextes. le fichier en tant que variable -> on l'ouvre en lecture et on met en minuscule.
# on va extraire les mots autour de "image" dont 1 mot avant et après :
tous_les_mots = texte.split()
mots_autour_image = []

for i, mot in enumerate(tous_les_mots):
    if mot == "image":
        # on prend le mot d'avant
        if i > 0:
            mots_autour_image.append(tous_les_mots[i-1])
        # on prend le mot d'après
        if i < len(tous_les_mots) - 1:
            mots_autour_image.append(tous_les_mots[i+1])

# nettoyage :
mots_propres = []
for mot in mots_autour_image:
    if mot not in stopwords_fr and len(mot) > 2 and mot.isalpha():
        mots_propres.append(mot)

# nuage de mots :
nuage = WordCloud(width=800, height=400, background_color="white").generate(" ".join(mots_propres))

# on affiche le wordcloud
plt.imshow(nuage)
plt.axis("off")
plt.title("Mots autour de 'image'")

# enregistrer dans un dossier image :
os.makedirs("../images", exist_ok=True)
plt.savefig("../images/nuage-fr.png", dpi=300, bbox_inches='tight')
print("✓ Nuage sauvegardé dans ../images/nuage-fr.png")

plt.show()

#exécuter sur le terminal : entrer dans l'environnement virtuel, puis faire : python wordcloud-fr.py
