#!/usr/bin/bash

FICHIER_HTML="$1"

echo -e "<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="utf-8">

  </head>
  <body>


  <center>
<h1 class=titre>Analyse</h1>

 </center>

 <h3>Déroulement</h3>
			<p class=paragraphe>Au départ, nous avions envisagé de prendre le mot “homme”. Mais, nous nous sommes questionnés sur son utilisation car il peut poser des difficultés en français, comme le fait de désigner l'être humain et qu'aujourd'hui, les personnes l'utilisent davantage avec une majuscule.

			D’un autre côté, nous avions eu comme idée, le mot “image”. Ce mot nous est venu car en effectuant les commandes de Bulma, nous avons observé que nous pouvions aussi ajouter des images. Cela nous a également fait penser à des icônes mais aussi à l’image que l’on peut renvoyer. On s'est interrogé sur sa polysémie.</p>

			<p> Nous avons décidé de nous pencher sur le mot "image" car il nous a parru plus intéressant pour observer les différentes polysémies, notamment dans les langues que nous avons choisies : le tamoul, le vietnamien, le français.			</p>


			<h3>Méthodes</h3>
				<p>Tout d'abord, en choisissant ce mot, nous étions persuadés que nous rencontrerions différents sens dans la langue française et notamment dans divers domaines, son sens ne serait pas identique. C'est pour cela que nous l'avions choisi. Nous avons émis quelques hypothèses selon les deux autres langues choisies :</p>

				<p>- le mot “image” en tamoul aurait un même mot mais des sens différents, comme en français.</p>

				<p>- selon nous, le mot image dans les langues (vietnamienne, française, tamoul) auraient tous les mêmes sens en français.</p>

				<p>Nous cherchons à observer si le mot a le même sens dans toutes les autres langues choisies.</p>

				<p>Pour ce projet, chaque étudiant a sa propre langue qu'il a choisie. Nous avons cherché au moins cinquante URL valides pour chaque langue et les avions affichés dans un tableau. Pour la sélection des URL, nous avons cherché le mot et pris ceux qui apparaissaient directement. Puis, nous avions cherché le mot au singulier dans les différents domaines dans lequel il pourrait apparaitre afin d'observer ses différents usages et contextes.</p>


	<h3>Analyse</h3>


	<h3>Conclusion</h3>


<style>

	.titre {
		color: darkblue;
		background-color: white;
		display: inline-block;
		padding: 15px 150px;
		border-radius: 8px;
			}

		body {
			background-color: #e6f2ff;
			}
</style>

	</body>
	</html>" > $FICHIER_HTML

#excécuter : ./analyse.sh analyse.html
