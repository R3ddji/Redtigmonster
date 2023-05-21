# Service Web

Le service web qui tourne est un serveur NextJs que nous allons mettre derrière un reverse proxy avec un certificat SSL. 

## Configuration

Pour notre rendu nous allons installer l'application de la demo de nextjs et non celle qui tourne réellement sur le service web, cependant l'installation reste la même:

nous allons partir d'une machine installée comme suit:

Tout d'abord il nous faut node et npm
```
user1@debian-patron:~$ sudo apt install nodejs -y
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Le paquet suivant a été installé automatiquement et n'est plus nécessaire :
  linux-image-5.10.0-20-amd64
Veuillez utiliser « sudo apt autoremove » pour le supprimer.
Les paquets supplémentaires suivants seront installés : 
[...]
user1@debian-patron:~$ node -v
v12.22.12
user1@debian-patron:~$ sudo apt install npm -y
[...]
user1@debian-patron:~$ npm --version
7.5.2
```
pour une raison obscure node et npm ne sont pas à la bonne version, node doit être au moins en version 16.8 pour nextJs, nous allons donc les mettre à jour, pour cela nous allons utiliser le packet n de npm qui nous simplifie la tache mais d'abord mettons à jour npm:
```
user1@debian-patron:~$ sudo npm install -g npm@latest

removed 1 package, and changed 62 packages in 2s

27 packages are looking for funding
  run `npm fund` for details

```

```
user1@debian-patron:~$ sudo npm install -g n

added 1 package, and audited 2 packages in 1s

found 0 vulnerabilities
user1@debian-patron:~$ sudo n lts
  installing : node-v18.16.0
       mkdir : /usr/local/n/versions/node/18.16.0
       fetch : https://nodejs.org/dist/v18.16.0/node-v18.16.0-linux-x64.tar.xz
     copying : node/18.16.0
   installed : v18.16.0 (with npm 9.5.1)

Note: the node command changed location and the old location may be remembered in your current shell.
         old : /usr/bin/node
         new : /usr/local/bin/node
If "node --version" shows the old version then start a new shell, or reset the location hash with:
hash -r  (for bash, zsh, ash, dash, and ksh)
rehash   (for csh and tcsh)
user1@debian-patron:~$ sudo n prune
```
après un reboot nous pouvons voir:
```
user1@debian-patron:~$ node -v
v18.16.0
```
puis nous créons notre application nextJs

```
user1@debian-patron:~$ npx create-next-app@latest nextjs-blog --use-npm --example "https://github.com/vercel/next-learn/tree/master/basics/learn-starter"
Need to install the following packages:
  create-next-app@13.4.3
Ok to proceed? (y) y
Creating a new Next.js app in /home/user1/nextjs-blog.

Downloading files from repo https://github.com/vercel/next-learn/tree/master/basics/learn-starter. This might take a moment.

[...]
```
il faut maintenant la "builder", pour cela:
```
user1@debian-patron:~/nextjs-blog$ npm run build

> build
> next build

[...]
```
une fois cela fait nous allons créer notre service systemd afin de pouvoir lancer notre serveur grâce au systemd, ici notre utilisateur s'appelle user1 mais sur serveur web ce sera l'utilisateur dédié au service.

```
user1@debian-patron:~/nextjs-blog$ sudo vim /lib/systemd/system/nextjs.service
[sudo] Mot de passe de user1 : 
```
[nextjs.service](files/nextjs.service)

puis nous allons faire en sorte de lancer le  service au démarrage de la machine et le lancer.

```
user1@debian-patron:~/nextjs-blog$ sudo systemctl enable nextjs
Created symlink /etc/systemd/system/multi-user.target.wants/nextjs.service → /lib/systemd/system/nextjs.service.
user1@debian-patron:~/nextjs-blog$ sudo systemctl start nextjs
user1@debian-patron:~/nextjs-blog$ sudo systemctl status nextjs
● nextjs.service - NodeJS server
     Loaded: loaded (/lib/systemd/system/nextjs.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2023-05-21 23:49:02 CEST; 10s ago
    Process: 795 ExecStartPre=/usr/local/bin/npm install (code=exited, status=0/SUCCESS)
    Process: 806 ExecStartPre=/usr/local/bin/npm run build (code=exited, status=0/SUCCESS)
   Main PID: 873 (npm run start)
      Tasks: 41 (limit: 2323)
     Memory: 112.1M
        CPU: 4.009s
     CGroup: /system.slice/nextjs.service
             ├─873 npm run start
             ├─884 sh -c next start
             ├─885 node /home/user1/nextjs-blog/node_modules/.bin/next start
             ├─896 /usr/local/bin/node /home/user1/nextjs-blog/node_modules/next/dist/compiled/jest-worker/processChild.js
             └─907 /usr/local/bin/node /home/user1/nextjs-blog/node_modules/next/dist/compiled/jest-worker/processChild.js

mai 21 23:49:01 debian-patron npm[818]: + First Load JS shared by all              73.1 kB
mai 21 23:49:01 debian-patron npm[818]:   ├ chunks/framework-cda2f1305c3d9424.js   45.2 kB
mai 21 23:49:01 debian-patron npm[818]:   ├ chunks/main-c33f0e9577fa29d8.js        26.8 kB
mai 21 23:49:01 debian-patron npm[818]:   ├ chunks/pages/_app-aea6920bd27938ca.js  195 B
mai 21 23:49:01 debian-patron npm[818]:   └ chunks/webpack-ee7e63bc15b31913.js     815 B
mai 21 23:49:01 debian-patron npm[818]: ○  (Static)  automatically rendered as static HTML (uses no initial props)
mai 21 23:49:02 debian-patron systemd[1]: Started NodeJS server.
mai 21 23:49:02 debian-patron npm[873]: > start
mai 21 23:49:02 debian-patron npm[873]: > next start
mai 21 23:49:03 debian-patron npm[885]: - ready started server on 0.0.0.0:3000, url: http://localhost:3000
```

Le service tourne sur le port 3000 mais nous voulons un service web classique qui tournerait sur le port 80 ou 443 pour l'https, nous allons nous allons donc installer notre reverse proxy: Nginx, celui ci va envoyer le trafic venant de ces ports vers le port 3000 sur lequel écoute le serveur nextjs

ensuite il faut s'occuper du certificat SSL, nous allons le faire avec Certbot