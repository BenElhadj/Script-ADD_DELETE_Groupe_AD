     # Import de Module Active Directory
	Import-Module ActiveDirectory

# Vérifie et supprime les espaces, les tabulations et les entrées dans le fichier pc_to_do.txt
(gc .\pc_to_do.txt) | ? {$_.trim('[^A-Za-z0-9]+') -ne ""} |
Foreach { $_.trim() -Replace ("(^\s+|\s+|\s+$)")," "} | set-content .\pc_to_do.txt
# Vérifie et supprime les espaces, les tabulations et les entrées dans le fichier to_add.txt
 (gc .\to_add.txt) | ? {$_.trim('[^A-Za-z0-9]+') -ne ""} |
Foreach { $_.trim() -Replace ("(^\s+|\s+|\s+$)")," "} | set-content .\to_add.txt
# Vérifie et supprime les espaces, les tabulations et les entrées dans le fichier to_delete.txt
 (gc .\to_delete.txt) | ? {$_.trim('[^A-Za-z0-9]+') -ne ""} |
Foreach { $_.trim() -Replace ("(^\s+|\s+|\s+$)")," "} | set-content .\to_delete.txt
# Vérifie et supprime les espaces, les tabulations et les entrées dans le fichier sensitive_group.txt
 (gc .\sensitive_group.txt) | ? {$_.trim('[^A-Za-z0-9]+') -ne ""} |
Foreach { $_.trim() -Replace ("(^\s+|\s+|\s+$)")," "} | set-content .\sensitive_group.txt

# Importer du fichier la liste de PC à traiter
	$ListePC = Get-Content -Path ".\pc_to_do.txt"
# Importer du fichier les Groupes à ajouter au PC à traiter
	$to_add = Get-Content -Path ".\to_add.txt"
# Importer du fichier les Groupes à supprimer du PC à traiter
	$to_delete = Get-Content -Path ".\to_delete.txt"
# Importer du fichier les Groupes sensible au démarrage du PC
	$SENSITIVE_group = Get-Content -Path ".\sensitive_group.txt"

# Préparation fichier de suivi
	$outfile = ".\suivi_script.csv"
	$newcsv = {} | Select "Hostname", "Old_group_delete", "New_version_installed", "PC_sensible" | Export-Csv $outfile
	$csvfile = Import-Csv $outfile

# Si le fichier pc_to_do.txt est pas vide
if (!($ListePC))
{
    "`n`n`t`tLe fichier `"pc_to_do.txt`" est vide il n'y a pas de PC à traiter"
}


# Demande de confirmation si le fichier sensitive_group.txt est vide
if (!($SENSITIVE_group))
{
    "`n`n`t`t`t`t`t`t`t`t`t`t`t   ATTENTION !!!"
    "`n`n`t`t`t`t`t`t`t`t  LA LISTE DE GROUPE SENSIBLE EST VIDE"
    "`t`t`t`t`t`t`t   TOUS LES PC SERONT TRAITÉS SANS EXCEPTIONS"
    "`n`n`t`t`t  Si vous souhaitez continuer, écrivez [OUI] / [YES], puis appuyez sur entrée."
    "`n`t`t Pour quitter le programme, appuyez sur n'importe quelle autre touche et/ou sur entrée."     

    switch ($carry_out =  Read-Host)
    {
        YES
        {
            Continue
        }
        OUI
        {
            Continue
        }
        default
        {
            exit
        }
    }

}

# Boucle globale qui va traiter chacun des PC
Foreach ($PC in $ListePC)
{
    if ($(Get-ADComputer $PC) -match $PC )
    {
        "`n`n`n======> Démarrage du traitement du PC [$PC]:`n`n`n"

# MAJ fichier de suivi avec le nom du PC actuellement traité
        $csvfile.Hostname = $PC

# Démarrage capture traces script par PC
        $log = $PC + ".txt"
        Start-Transcript -Path ".\logs_script\$log" -Force

# Recherche des groupes de ce PC
        $ListeGroup = Get-ADComputer $PC -Properties MemberOf   

# Si le fichier sensitive_group.txt est pas vide
        if (!($SENSITIVE_group))
        {
            "`n`n`t`t`t`t   ATTENTION !!!`n`t`t`tLA LISTE DE GROUPE SENSIBLE EST VIDE`n`t`t     TOUS LES PC SERONT TRAITÉS SANS EXCEPTIONS"
        }

# Stocke dans une variable la liste des groupes indiquant un PC sensible au reboot
        $i = 1
        Foreach ($not_allowed in $SENSITIVE_group)
        {
            if ($ListeGroup.memberof -match $not_allowed)
            {
                if ($i -eq '1')
                {
                    "`r`t<!> ATTENTION ce PC contient un(des) groupe(s) sensible(s) au redémarrage:"
                    "`r"
                }
                "`t`t-  $not_allowed"
                $i++
            }
        }

# Si le PC est un poste sensible au reboot, on ne le traite pas
        if ($i -gt '1')
        {
            "`rPC sensible, à traiter à part"
            $csvfile.PC_sensible = "OUI"
            $csvfile.Old_group_delete = "" 
            $csvfile.New_version_installed = ""     
        }

# Sinon, on le traite
        else
        {
            $csvfile.PC_sensible = "NON" 

# Stocke dans une variable la liste des groupes liés à Citrix
            $reponseGroupeSccmCitrix = ($ListeGroup.memberof -match $to_delete)

# Stocke dans fichier de trace les groupes Citrix dont le PC était membre avant le traitement qui va suivre
# Pour tous les groupes liés à Citrix trouvés...

# Démarrage de la suppression les groupes spécifiés dans le fichier to_delete.txt
            "`rDémarrage de la suppression des groupes`r**********************`r"

# Si le fichier to_delete.txt n'est pas vide, on rentre dans la boucle

            $i = 1
            if ($to_delete)
            {

# On stock les groupes un seul a chaque boucle dans ($Group_to_delete)
                Foreach ($Group_to_delete in $to_delete)
                {
        
# On compare le groupe de la ligne actuel avec le fichier to_add.txt
# Si le groupe de la ligne actuel correspond a un groupe a ajouter on ne fait rien pour le moment 
                if ($to_add -match $Group_to_delete)
                {}
   
# Si le groupe de la ligne actuel ne correspond pas a un groupe a ajouter on le supprime
                elseif ($ListeGroup.memberof -match $Group_to_delete)
                {
                    if ($i -eq '1')
                    {
                        "`r`tSuppression du groupe:"
                        "`r"
                        $i++
                    }
                    Remove-adgroupmember -identity $Group_to_delete -members $PC$  -Confirm:$false
                    "`t`t-  $Group_to_delete"
                }
            }
            $i = 1

# On stock les groupes un seul a chaque boucle dans ($Group_to_delete)
            Foreach ($Group_to_delete in $to_delete)
            {

# On compare pour la deuxiemme fois le groupe de la ligne actuel avec le fichier to_add.txt
# Si le groupe de la ligne actuel correspond a un groupe a ajouter on affiche (... ne sera pas supprimé ...)
                if ($to_add -match $Group_to_delete)
                {
                    if ($i -eq '1')
                    {
                        "`r`tCe(s) groupe(s) ne ser(a/ont) pas supprimé(s), il(s) f(ait/ont) partie des groupes à installer:"
                        "`r"
                        $i++
                    }
                    "`t`t-  $Group_to_delete"
                }
                elseif ($ListeGroup.memberof -match $Group_to_delete)
                {}				
            }
        }

# Si le fichier to_delete.txt est vide, on affiche le message (... pas de groupe à supprimer)
        else
        {
            "`r`rLe fichier `"to_delete.txt`" est vide il n'y a pas de groupe à supprimer"
        }

# Démarrage de l'ajout sdes groupes spécifiés dans le fichier to_add.txt
        "`r`rDémarrage de l'ajout des groupes`r**********************`r"
# Si le fichier to_add.txt n'est pas vide, on rentre dans la boucle
        if ($to_add)
        {
            $i = 1
# On stock les groupes un seul a chaque boucle dans ($Group_to_add)

            Foreach ($Group_to_add in $to_add)
            {

# Si le groupe de la ligne actuel correspond a un groupe qui est deja installer on ne fait rien pour le moment 
                if ($ListeGroup.memberof -match $Group_to_add)
                {}

# Si le groupe de la ligne actuel ne correspond a aucun groupe deja installer on l'ajoute
                else
                {
                    if ($i -eq '1')
                    {
                        "`r`tAjout du groupe:"
                        "`r"
                        $i++
                    }
                    Add-ADGroupMember -identity $Group_to_add -members $PC$ -Confirm:$false
                    "`t`t-  $Group_to_add"
                }
            }
            $i = 1

# On stock dans un deuxiemme boucle les groupes un seul a chaque boucle dans ($Group_to_add)
            Foreach ($Group_to_add in $to_add)
            {

# Si le groupe de la ligne actuel correspond a un groupe qui est deja installer, on affiche le message (... est déjà installée.)
                if ($ListeGroup.memberof -match $Group_to_add)
                {
                    if ($i -eq '1')
                    {
                        "`r`tCe(s) groupe(s) est/sont déjà installé(s):"
                        "`r"
                        $i++
                    }
                    "`t`t-  $Group_to_add"
                }
                else
                {}
            }
        }

# Si le fichier to_add.txt est vide, on affiche le message (... pas de groupe à ajouter)
        else
        {
            "`r`rLe fichier `"to_add.txt`" est vide il n'y a pas de groupe à ajouter"
        }
            "`r`r"
            $ListeGroup = Get-ADComputer $PC -Properties MemberOf

# Démarrage de la verification et l'affichage de resultat
            "`rDémarrage de la verification`r**********************`r"

# Démarrage de la verification des groupes a supprimer un par un dans un boucle

            if ($to_delete)
            {
                $i = 1
                Foreach ($Group_to_delete in $to_delete)
                {
                    if ($to_add -match $Group_to_delete)
                    {}

# Si le groupe actuel est toujours present on affiche le nom de groupe et (... N'est pas supprimé ...) est on stock false dans ($test_delete)
                    elseif ($ListeGroup.memberof -match $Group_to_delete)
                    {
                        if ($i -eq '1')
                        {
                            "`r`tce(s) groupe(s) (n'est/ne sont) toujours pas installé(s):"
                            "`r"
                            $i++
                        }
                        "`r<!> ( $Group_to_delete )-`t`t`tN'est pas supprimé <!>."
                        $test_delete = $false
                    }
				
                }

# Si ($test_delete) = false on affiche (... Attention !!! Présence d'anciens groupes ...)
                if ($test_delete -eq "false")
                {
                    "`r`r`t`t`t`t`t**********************`r`t`t`<!> Attention !!! Présence d'anciens groupes, même après traitement <!>.`r`t`t`t`t`t**********************`r"
                }

# Si non on affiche (... Tous les anciens groupes ont bien été supprimés ...)
                else
                {
                    "`rTous les anciens groupes ont bien été supprimés.`r"
                }
            }
            else
            {
                "`r`rLe fichier `"to_delete.txt`" est vide, aucun groupe n'a été supprimé"
            }
# Démarrage de la verification des groupes a ajouter un par un dans un boucle

            if ($to_add)
            {
                $i = 1
                Foreach ($Group_to_add in $to_add)
                {
                    if ($ListeGroup.memberof -match $Group_to_add)
                    {}

# Si le groupe actuel n'est pas present on affiche le nom de groupe et (... N'est toujours pas installé ...) est on stock false dans ($test_add)
                    else
                    {
                        if ($i -eq '1')
                        {
                            "`r`tce(s) groupe(s) (n'est/ne sont) toujours pas installé(s):"
                            "`r"
                            $i++
                        }
                        "`t`t-  $Group_to_add"
                        $test_add = $false
                    }
                }

# Si ($test_add) = false on affiche (... Attention !!! Il y a des groupes qui ne sont toujours pas installés ...)
                if ($test_add -eq "false")
                {
                    "`r`r`t`t`t`t`t**********************`r`t`t`<!> Attention !!! Il y a des groupes qui ne sont toujours pas installés, même après traitement <!>.`r`t`t`t`t`t**********************`r"
                }
    
# Si non on affiche (... Tous les groupes sont ajoutés avec succès ...)
                else
                {
                    "`rTous les groupes sont ajoutés avec succès.`r`r**********************"
                }
            }
            else
            {
                "`r`rLe fichier `"to_add.txt`" est vide, aucun groupe n'a été ajouté"
            }
        }
    }
    else
    {
        "`n`n`n======> le PC [$PC] n'existe pas/plus dans l'AD !!!`n`n`n"
        continue
    }

# Arrêt capture traces script pour ce PC en cours de traitement  
    Stop-Transcript

# Export des infos relevées au cours du script (pour ce PC en cours de traitement), dans le fichier de suivi csv
    $csvfile | Export-CSV $outfile –Append

}
