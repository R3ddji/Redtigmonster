# Config des machines

Ici retrouver les manipulations à appliquer sur chaque machine.

## Mise en place des users

**Création d'utilisateur**

```
$adduser [nom]
```

**Ajout au groupe sudo**

```
$usermod -g sudo [nom]
```

## Mise en place du réseaux

**Configuration IP static** 

```
$cat /etc/netplan/00-installer-config.yaml 
# This is the network config written by 'subiquity'
network:
  version: 2
  ethernets:
    eno1:
      dhcp4: false
      addresses: [10.10.1.3/28]
      nameservers:
        addresses: [1.1.1.1]
      routes:
        - to: default
          via: 10.10.1.14
```

**Pour appliquer la configuration**

```
$netplan apply
```

## Mise en place Fail2Ban

**Installation de fail2ban**

```
$sudo apt install fail2ban -y
```

**Configuration de fail2ban**

```
$sudo cat /etc/fail2ban/jail.conf
...
...
# [sshd]
enabled = true
bantime = 4w
maxretry = 3
```

## Configuration SSH

**Pour se connecter à une des machines à distances il est nécessaire de générer une clé sur la machine local.**

```
$ssh-keygen
```

**Copie de la clé sur la machine distante.**

```
$ssh-copy-id utilisateur@adresse_ip_du_serveur
```
