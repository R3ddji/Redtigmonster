# Mise en place de la backup

Création du script.

```
$cat backup.sh

#!/bin/bash 
scp -r backupuser@honeypot:/pentbox/other/log_honeypot.txt ~/backup/

scp -r backupuser@elk:/var/log/mikrotik.log ~/backup/

scp -r backupuser@elk:/var/log/auth.log ~/backup/
```


