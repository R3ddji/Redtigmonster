# STACK ELK
Ce fichier contient une documentation d'installation de la stack ELK ansi que FileBeats pour l'OS ubuntu_22_04_LTS.

**PRÉREQUIS**
- Ubuntu Server 22.04
- Java 11 ou version ultérieur
- 2 CPU et 4GB RAM

## INSTALLATION DE JAVA
- JRE/JDK
```
sudo apt install default-jre && sudo apt install default-jdk
```
- Paramêtrer la variable d'environement
```
sudo vim /etc/environment
```
- Mettre le chemin de openjdk
```
LS_JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
```
- Charger la variable d'environement
```
source /etc/environment
```

## INSTALLATION DE ELASTICSEARCH
- Importer la clé GPG publique d'Elasticsearch dans APT
```
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch |sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
```
- Ajouter la liste des sources élastiques au sources.list.d
```
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
```
- Mettre à jours vos paquets
```
sudo apt update
```
- Installer elasticsearch
```
sudo apt install elasticsearch
```

## CONFIGURATION DE ELASTICSEARCH
- Modifier le fichier elasticsearch.yml
```
sudo vim /etc/elasticsearch/elasticsearch.yml
```
- Changer les paramètres suivants comme ci-dessous (adaptez vos informations si besoin)
```
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
discovery.seed_hosts: ["10.10.1.1", "10.10.1.3", "10.10.1.4", "127.0.0.1"]    /!\à adapter
```
- Lancer Elasticsearch et faire en sotre qu'il se lance à chaque démarage
```
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
```
- Tester si votre service elasticsearch reçois vos requêtes
```
curl -X GET "localhost:9200"
```
- La sortie devraie ressembler à ceci
```
{
  "name" : "elk",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "JYJIw-RWTY2hzGLaQ92aLA",
  "version" : {
    "number" : "8.7.1",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "f229ed3f893a515d590d0f39b05f68913e2d9b53",
    "build_date" : "2023-04-27T04:33:42.127815583Z",
    "build_snapshot" : false,
    "lucene_version" : "9.5.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

## INSTALLATION ET CONFIGURATION DE KIBANA
- Installer Kibana
```
sudo apt install kibana
```
- Modifier le fichier kibana.yml
```
sudo vim /etc/kibana/kibana.yml
```
- Changer les paramètres suivants comme ci-dessous (adaptez vos informations si besoin)
```
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
```
- Lancer Kibana et faire en sotre qu'il se lance à chaque démarage
```
sudo systemctl start kibana
sudo systemctl enable kibana
```
- Testez si Kibana fonctionne
```
http://ip_de_votre_server:5601
```
![](/ELK/img/kibana_home.png)

## INSTALLATION ET CONFIGURATION DE LOGSTASH
- Installer Logstash
```
sudo apt install logstash
```
- Créer et modifier 02-beats-input.conf, où vous configurerez votre entrée Filebeat
```
sudo vim /etc/logstash/conf.d/02-beats-input.conf
```
```
input {
  beats {
    port => 5044
  }
}
```
- Créer et modifier un fichier de configuration appelé 30-elasticsearch-output.conf
```
sudo vim /etc/logstash/conf.d/30-elasticsearch-output.conf
```
```
output {
  if [@metadata][pipeline] {
	elasticsearch {
  	hosts => ["localhost:9200"]
  	manage_template => false
  	index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  	pipeline => "%{[@metadata][pipeline]}"
	}
  } else {
	elasticsearch {
  	hosts => ["localhost:9200"]
  	manage_template => false
  	index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
	}
  }
}
```
- Tester votre configuration Logstash avec cette commande
```
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
```
```
Config Validation Result: OK. Exiting Logstash
```
- Lancer Logstash et faire en sotre qu'il se lance à chaque démarage
```
sudo systemctl start logstash
sudo systemctl enable logstash
```

## INSTALLATION ET CONFIGURATION DE FILEBEAT
- Installer FileBeat
```
sudo apt install filebeat
```
- Modifier le fichier filebeat.yml
```
sudo vim /etc/filebeat/filebeat.yml
```
- Commentez ces lignes
```
#output.elasticsearch:
  # Array of hosts to connect to.
  # hosts: ["localhost:9200"]
```
- Decommentez ces lignes
```
output.logstash:
  # The Logstash hosts
  hosts: ["10.10.1.2:5044"]
```
- Activer le module system de FileBeat
```
sudo filebeat modules enable system
```
- Lister les modules
```
sudo filebeat modules list
```
- Modifier le fichier system.yml
```
sudo vim /etc/filebeat/modules.d/system.yml
```
- Mettre syslog et auth en: true
```
- module: system
  # Syslog
  syslog:
    enabled: true
    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    #var.paths:

  # Authorization logs
  auth:
    enabled: true

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    #var.paths:
```
- Activer les piplines Filebeat
```
sudo filebeat setup --pipelines --modules system
```
- Charger le modèle
```
sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["10.10.1.2:9200"]'
```
```
Output
Index setup finished.
```
- Vérifiezr les informations de version, charger les tableaux de bord lorsque Logstash est activé, désactiver la sortie Logstash et activer la sortie Elasticsearch
```
sudo filebeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['10.10.1.2:9200'] -E setup.kibana.host=10.10.1.2:5601
```
```
Overwriting ILM policy is disabled. Set `setup.ilm.overwrite: true` for enabling.

Index setup finished.
Loading dashboards (Kibana must be running and reachable)
Loaded dashboards
Loaded Ingest pipelines
```
- Lancer Filebeat et faites en sotre qu'il se lance à chaque démarage
```
sudo systemctl start filebeat
sudo systemctl enable filebeat
```
- Vérifier que Elasticsearch reçois bien les donné via l'index Filebeat
```
 curl -XGET 'http://10.10.1.2:9200/filebeat-*/_search?pretty'
```
```
[...]
      {
        "_index" : "filebeat-8.7.1-2023.05.21",
        "_id" : "007uPogBKe296u7f6r1X",
        "_score" : 1.0,
        "_source" : {
          "agent" : {
            "name" : "elk",
            "id" : "c1690cbe-5197-4b9e-bd26-e24deb4daf42",
            "ephemeral_id" : "0a3bb919-0a79-4166-a2ed-617fc99a5c67",
            "type" : "filebeat",
            "version" : "8.7.1"
          },
          "process" : {
            "name" : "dstnat"
          },
          "log" : {
            "file" : {
              "path" : "/var/log/syslog"
            },
            "offset" : 15399161
          },
          "fileset" : {
            "name" : "syslog"
          },
          "message" : "in:br-wan out:(unknown 0), connection-state:new src-mac e4:41:64:92:9d:70, proto TCP (SYN), 179.43.177.244:37104->82.126.156.59:80, len 60",
          "tags" : [
            "beats_input_codec_plain_applied"
          ],
          "input" : {
            "type" : "log"
          },
          "@timestamp" : "2023-05-21T17:30:15.000Z",
          "system" : {
            "syslog" : { }
          },
          "ecs" : {
            "version" : "1.12.0"
          },
          "related" : {
            "hosts" : [
              "MikroTik"
            ]
          },
          "service" : {
            "type" : "system"
          },
          "@version" : "1",
          "host" : {
            "hostname" : "MikroTik",
            "os" : {
              "kernel" : "5.15.0-72-generic",
              "codename" : "jammy",
              "name" : "Ubuntu",
              "type" : "linux",
              "family" : "debian",
              "version" : "22.04.2 LTS (Jammy Jellyfish)",
              "platform" : "ubuntu"
            },
            "containerized" : false,
            "ip" : [
              "10.10.1.2",
              "fe80::7254:d2ff:fe96:51ce"
            ],
            "name" : "elk",
            "id" : "df85b301d16244078d67b82fec62556e",
            "mac" : [
              "70-54-D2-96-51-CE"
            ],
            "architecture" : "x86_64"
          },
          "event" : {
            "ingested" : "2023-05-21T15:30:24.983083835Z",
            "original" : "May 21 17:30:15 MikroTik dstnat: in:br-wan out:(unknown 0), connection-state:new src-mac e4:41:64:92:9d:70, proto TCP (SYN), 179.43.177.244:37104->82.126.156.59:80, len 60",
            "timezone" : "+00:00",
            "kind" : "event",
            "module" : "system",
            "dataset" : "system.syslog"
          }
        }
      }
[...]
```

## DASHBOARD
Une fois sur votre interace web vous pouvez cliquer sur les trois traits à gauche et aller dans discover
![](/ELK/img/kibana_discover.png)