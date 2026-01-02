from pathlib import Path
from wordcloud import WordCloud
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image
import re
from collections import Counter

# --- Dossiers et fichiers ---
SCRIPT_DIR = Path(__file__).parent
dump_file = SCRIPT_DIR.parent / 'pals' / 'dumps-text-tam.txt'
stopwords_file = SCRIPT_DIR / 'stopwords.txt'
images_dir = SCRIPT_DIR.parent / 'images'
images_dir.mkdir(exist_ok=True)

mask_file = images_dir / 'camera-mask.png'
if not mask_file.exists():
    raise FileNotFoundError(f"Le masque {mask_file} est introuvable.")

output_file = images_dir / 'nuage-mots-tam.png'

# --- Lecture du texte ---
with open(dump_file, 'r', encoding='utf-8', errors='replace') as f:
    text = f.read()

# --- Stopwords ---
if stopwords_file.exists():
    with open(stopwords_file, 'r', encoding='utf-8') as f:
        stopwords = set(word.strip().lower() for word in f if word.strip())
else:
    stopwords = set()
    print(f"Attention : {stopwords_file} non trouvé. Aucun stopword utilisé.")

# --- Extraction des mots tamouls complets ---
# \u0B80-\u0BFF couvre tous les caractères tamouls
words = re.findall(r'[\u0B80-\u0BFF]+', text)

# --- Filtrage stopwords ---
words = [word for word in words if word.lower() not in stopwords]

# --- Comptage des fréquences ---
word_freq = dict(Counter(words))

# --- Masque ---
mask_image = np.array(Image.open(mask_file))

# --- Police Unicode complète ---
font_path = '/usr/share/fonts/truetype/noto/NotoSansTamil-Regular.ttf'  # adapte selon ton système

# --- Génération du nuage ---
wordcloud = WordCloud(
    width=mask_image.shape[1],
    height=mask_image.shape[0],
    background_color='white',
    colormap='viridis',
    max_words=200,
    mask=mask_image,
    contour_color='black',
    contour_width=3,
    font_path=font_path
).generate_from_frequencies(word_freq)

# --- Sauvegarde ---
wordcloud.to_file(output_file)
print(f"Nuage de mots généré et enregistré dans {output_file}")

# --- Affichage ---
plt.figure(figsize=(10, 8))
plt.imshow(wordcloud, interpolation='bilinear')
plt.axis('off')
plt.show()
