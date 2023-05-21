Ce fichier contient une documentation d'installation de Rsyslog pour l'OS ubuntu_22_04_LTS

# RSYSLOG: INSTALLATION ET CONFIGURATION SERVEUR
- Installer rsyslog
```
sudo apt install rsyslog
```
- Modifier le fichier rsyslog.conf
```
sudo vim /etc/rsyslog.conf
```
```
[...]
# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")
[...]
```
- Lancer Rsyslog et et faire en sotre qu'il se lance à chaque démarage
```
sudo systemctl start rsyslog
sudo systemctl enable rsyslog
```

# RSYSLOG: INSTALLATION ET CONFIGURATION CLIENT
- Installer rsyslog
```
sudo apt install rsyslog
```
- Créer et modifier le fichier 50-default.conf
```
sudo vim /etc/rsyslog.d/50-default.conf
```
- Ajouter cette ligne
```
auth,authpriv.*                 @10.10.1.2:514
```
- Pour les logs du routeur créer et modifier le fichier mikrotik.log
```
sudo touch /var/log/mikrotik.log
```
- Ajouter les bon droits pour ce fichier
```
sudo chown syslog:adm /var/log/mikrotik.log
```
- Ajouter ces ligner dans le fichier 50-default.conf du serveur
```
# Mikrotik Logs Conf
if ($fromhost-ip == "10.10.1.14" ) then /var/log/mikrotik.log
```

# CONFIGURATION DU MIKROTIK POUR L'ENVOIE DE LOG
- Une fois connecté au routeur faire
```
/system logging action add name="rsyslog" target=remote remote=10.10.1.2 remote-port=514;
```
- Ajouter les règles
```
system logging add topics=info action=rsyslog;
system logging add topics=error action=rsyslog;
system logging add topics=warning action=rsyslog;
system logging add topics=critical action=rsyslog;
```
- Redémarer le service rsyslog
```
sudo systemctl restart rsyslog.service
```