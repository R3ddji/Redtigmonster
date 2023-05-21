# Mise en place de la backup

## Création d'utilisateur spécifique ayant accès uniquement au contenu à backup sur les machines.

```
$adduser backupuser
```

Mise en place des permissions pour l'accès aux fichiers à backup sur chaque machines

```
$sudo chown backupuser [fichierbackup]
```

## Création du script.

```
$cat backup.sh

#!/bin/bash 
scp -r backupuser@honeypot:/pentbox/other/log_honeypot.txt ~/backup/

scp -r backupuser@elk:/var/log/mikrotik.log ~/backup/

scp -r backupuser@elk:/var/log/auth.log ~/backup/
```


