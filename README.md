# Script-ADD_DELETE_Groupe_AD
Script ADD_DELETE_Groupe_AD
Fichiers et prérequis 
1.	Prérequis
-	Ouvrez l'application Active Directory « en dur » et gardez-la ouverte tout au long du processus

2.	Fichier obligatoire pour le bon déroulement du script « AD_Group_check_delete_add.ps1 » :
-	sensitive_group.txt
-	pc_to_do.txt
-	to_add.txt
-	to_delete.txt

3.	Règle générale à respecter sur tous les fichiers :
•	Il ne faut pas faire :
o	Des espaces, ni au début ni à la fin de la ligne et au milieu non plus.
o	Des tabulations, ni au début ni à la fin de la ligne et au milieu non plus.
o	Les ponctuations, Ni au début ni à la fin de la ligne.
o	Les entrées, sauf une entre les lignes et pas à la fin.
•	Il faut faire :
o	Ecrire les ligne un par un.
o	Faire une seule entrée entre chaque ligne.
o	S'il s'agit de groupes, il vaut mieux avoir le copié tel qu'il est dans l'AD

4.	Contenu des fichiers :
	sensitive_group.txt :
-	Les groupes sensibles au démarrage de PC ou qui rend un pc sensible.
	pc_to_do.txt :
-	Les CI de pc à traiter. 
	to_add.txt :
-	Les groupes AD à ajouter.
	to_delete.txt :
-	Les groupes AD à supprimer.
Si vous souhaitez uniquement supprimer des groupes, vous devez vider le fichier "to_add.txt" (rien d'écrit dedans, pas d'espace, pas de tabulation, pas d'entrée, pas de ponctuation ...).
Si vous souhaitez uniquement ajouter des groupes, vous devez vider le fichier " to_delete.txt" (rien d'écrit dedans, pas d'espace, pas de tabulation, pas d'entrée, pas de ponctuation ...).

5.	Exécution du script : 
-	Démarrez Windows PowerShell, en tant qu'Administrateur.
o	Tapez la commande suivante :
	set-executionpolicy unrestricted
o	Confirmez par « O » (le o de oui).
-	Dans Windows PowerShell, Tapez les commandes suivantes, pour accéder au dossier :
o	cd ..\..\Scripts             ===>     indiquez le chemin d'accès au dossier Scripts
o	.\AD_Group_check_delete_add
