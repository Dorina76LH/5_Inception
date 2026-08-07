# Notes Docker — Perso

## 1. C'est quoi Docker

**Docker** : logiciel de virtualisation légère qui facilite le développement et le déploiement d'applications. Il package une app avec toutes ses dépendances nécessaires dans un **container**.

### Avant les containers
- Il fallait installer et configurer tous les services directement sur l'OS de chaque dev (en local)
- Le processus d'installation était différent d'une machine à l'autre
- Beaucoup d'étapes manuelles
- Configurer un environnement de dev était compliqué et peu reproductible

### Le processus de dev avec les containers
- Environnement de dev isolé (le container) avec tous les services et dépendances inclus
- On démarre un service en tant que container Docker avec une commande Docker identique quel que soit l'OS
- Docker **standardise** le processus de lancement d'un service, sur n'importe quel environnement de dev local

### Déploiement avant les containers
- Il fallait livrer l'artefact de l'application + des instructions d'installation
- L'équipe ops devait installer et configurer manuellement sur le serveur
- Risques : conflits de versions de dépendances, mauvaise communication entre équipes, erreurs humaines

### Déploiement avec les containers
- Docker embarque tout dans l'artefact : app (code) + config + dépendances
- Aucune config supplémentaire nécessaire sur le serveur
- Moins de place à l'erreur
- Le serveur a seulement besoin d'avoir le runtime Docker installé

---

## 2. Docker vs Virtual Machine

### Comment Docker fait tourner ses containers
Rappel de l'architecture d'un OS classique :
```
OS App Layer  ⇄  OS Kernel  ⇄  Hardware
```

**Docker virtualise uniquement la couche applicative (App Layer)**, pas le kernel.

| | Docker | VM |
|---|---|---|
| Kernel | Utilise le kernel de l'**hôte** (n'a pas son propre kernel) | A son propre kernel (OS invité complet) |
| Ce qu'il virtualise | Uniquement la couche App | L'OS complet |
| Taille des images | Petites (MB) — n'implémente qu'une seule couche | Grosses (GB) |
| Temps de démarrage | Secondes | Minutes (doit démarrer son propre kernel) |
| Compatibilité OS | Une image Linux ne tourne pas nativement sur le kernel Windows (containers = basés Linux) | Compatible avec tous les OS, car virtualisation complète |

**Schéma comparatif (empilement des couches) :**

VM :
```
[VM: App A + Guest OS]   [VM: App B + Guest OS]
--------------------------------------------------
                Host OS
--------------------------------------------------
              Physical Machine
```

Docker :
```
        Containerized Apps
[  App A  ]        [  App B  ]
--------------------------------------------------
                  Docker
--------------------------------------------------
                 Host OS
--------------------------------------------------
              Physical Machine
```

### Docker sur Mac / Windows
Comme les containers sont basés sur Linux et ne peuvent pas tourner directement sur le kernel Windows/Mac :
- **Docker Desktop** installe une couche d'hypervision avec un Linux léger en arrière-plan (pour fournir un kernel Linux)
- C'est ce qui permet d'utiliser des containers Linux sur macOS ou Windows

### Composants de Docker
- **Docker Engine** : serveur avec un processus daemon qui tourne en continu, `dockerd`. Il gère les images et les containers.
- **Docker CLI** : outil en ligne de commande (client)
- **Docker GUI** : interface graphique (Docker Desktop)

---

## 3. Image Docker vs Container

**Docker Image** : artefact/package qui contient tout ce qu'il faut pour faire tourner une app :
- Code source de l'app
- Runtime (ex : Node, npm)
- Couche OS (ex : Linux)

C'est un **template** qui définit comment un container sera concrètement créé et exécuté.

**Docker Container** : instance en cours d'exécution d'une image.
- ⚠️ À partir d'**une seule image**, on peut lancer **plusieurs containers** en parallèle → utile pour améliorer les performances (scalabilité, load balancing, etc.)

```
Dockerfile  --(build)-->  Image  --(run)-->  Container
```

- **Dockerfile** : blueprint (plan) pour construire une image
- **Image** : template pour lancer des containers
- **Container** : processus en cours d'exécution

---

## 4. Docker Hub, Registry, Repository

**Docker Hub** : système de stockage et de distribution pour les images Docker (Redis, Mongo, Postgres, etc.)
- Une équipe dédiée review et publie tout le contenu des repositories officielles
- Cette équipe travaille en collaboration avec les mainteneurs du logiciel et des experts sécurité

**Registry vs Repository**
- **Registry** : service qui fournit du stockage, une collection de repositories (ex : Docker Hub est une registry)
- **Repository** : collection d'images liées entre elles — même nom, différentes versions

```
Registry (ex: Docker Hub)
├── Repository "my_app"
│   ├── img 1.0
│   └── img 1.1
└── Repository "my_sce"
    ├── img 5.2
    └── img 5.3
```

**Versioning des images (tags)**
- Exemples : `redis:6.1`, `redis:6.2`
- Le tag `latest` correspond à la dernière image qui a été buildée

**Récupérer / pull une image**
```bash
docker pull nom_image:version
docker pull nginx:1.23
docker pull nginx          # pull la version "latest" par défaut
```

**Lancer un container**
```bash
docker run image_name:tag
docker run -d image_name:tag    # -d = detached, ne bloque pas le terminal (tourne en arrière-plan, n'affiche pas les logs)
```

Note : on peut aussi lancer un container sans avoir pull l'image au préalable — Docker la pull automatiquement si elle n'est pas présente localement.

**Commandes utiles**
```bash
docker ps              # liste les containers en cours d'exécution
docker ps -a            # liste TOUS les containers (en cours ou arrêtés)
docker images           # liste les images
docker logs cont_id      # affiche les logs d'un container
```

---

## 5. Port Binding

Une app à l'intérieur d'un container tourne dans un réseau Docker isolé → **pas accessible directement depuis le navigateur de l'hôte**.

Pour rendre le service accessible depuis l'extérieur, il faut **exposer le port du container vers un port de l'hôte** : c'est le **port binding**.

```
nginx (container)         laptop (hôte)
     80          <--------->    8080
```

```bash
docker run -d -p 8080:80 nginx:1.23
```
Format : `-p port_hôte:port_container`

⚠️ **Bonne pratique** : si possible, utiliser le même numéro de port côté hôte et côté container, pour éviter la confusion.
Exemple : MySQL → port 3306 côté container ET côté hôte : `-p 3306:3306`

---

## 6. Start / Stop des containers

```bash
docker run       # crée un NOUVEAU container, ne réutilise pas un container existant
docker ps        # affiche uniquement les containers en cours d'exécution (pas les arrêtés)
docker ps -a     # affiche tous les containers (en cours ET arrêtés)
docker stop cont_id   # stoppe un container en cours d'exécution
docker start cont_id  # redémarre un container existant (déjà créé, arrêté)
```

**Lancer un container avec un nom personnalisé, en arrière-plan, avec port binding :**
```bash
docker run --name nom_perso -d -p port_hote:port_container image:tag
```

---

## 7. Dockerfile — structure de base

Un **Dockerfile** est un fichier texte qui contient les commandes nécessaires pour construire (build) une image. Docker lit ces instructions pour assembler l'image, ligne par ligne.

Un Dockerfile part toujours d'une image de base (**"base image"**), définie par l'instruction `FROM`.

### Instructions principales

```dockerfile
# 1. Choisir l'image de base
FROM node:version

# 2. Copier des fichiers depuis l'hôte vers le container
COPY package.json /app/
#      ^source (hôte)  ^destination (container)

# Définir le répertoire de travail par défaut dans le container
WORKDIR /app

# 3. Installer les dépendances
RUN npm install

# Instruction exécutée quand le CONTAINER démarre (pas au build)
CMD ["npm", "start"]
```

**Build l'image à partir du Dockerfile**
```bash
docker build -t node-app:1.0 .
#                              ^ "." = build depuis le dossier courant
```

⚠️ **Notion de layers (couches)**
- Une image Docker est constituée de **layers empilés**
- Chaque instruction du Dockerfile crée **une nouvelle layer**
- Chaque layer est un "delta" (différence) par rapport à la précédente
- Docker met en cache les layers non modifiées → rebuild plus rapide si seule la fin du Dockerfile change

---

## 8. Persistance des données — Volumes

**Container = stateless / éphémère** → à la fermeture du container, toutes les données créées à l'intérieur sont perdues.

**Volume** : permet de stocker des données de façon **persistante**, en dehors du cycle de vie du container (les données survivent même si le container est supprimé).

---

## 9. Docker Compose

`docker-compose.yml` : fichier utilisé pour définir et lancer une application **multi-services** (plusieurs containers qui doivent communiquer entre eux), en une seule commande.

---

## 10. Résumé — vocabulaire clé

| Terme | Définition |
|---|---|
| **Dockerfile** | Blueprint (plan) pour construire une image |
| **Image** | Template pour lancer des containers |
| **Container** | Processus en cours d'exécution, instance d'une image |
| **Docker** | Outil qui package un logiciel pour le faire tourner sur n'importe quel hardware |

---

## 12. PID 1, daemons, et foreground vs background
 
### C'est quoi PID 1 ?
 
Les processus Unix sont organisés en arbre : chaque processus a un parent, sauf le tout premier, **PID 1**.
 
PID 1 (aussi appelé **init**) est l'ancêtre commun de tous les processus — c'est la fondation sur laquelle tous les autres tournent. Sur une machine classique, ce rôle est tenu par `init`/`systemd`, un vrai gestionnaire de processus.
 
### Le cas particulier des containers Docker
 
Un container **n'a pas de vrai `init`/`systemd`** par défaut. Le premier processus lancé dans le `CMD`/`ENTRYPOINT` devient automatiquement PID 1, qu'il soit conçu pour ce rôle ou non.
 
→ Conséquence directe : ce PID 1 doit être capable de bien gérer les signaux d'arrêt, sinon le container ne s'arrête pas proprement.
 
### Daemon vs foreground : le problème avec nginx
 
**Par défaut, nginx tourne en mode daemon** : il se lance, puis se "fork" en arrière-plan et se détache du terminal — le process principal se termine, un process enfant continue de tourner en background, invisible.
 
**Problème dans un container** : Docker est conçu pour faire tourner **un seul processus au premier plan (foreground)**. Si ce processus se termine (ou passe en arrière-plan comme le fait nginx par défaut), **Docker considère que le container a fini son travail et l'arrête**.
 
→ Résultat sans intervention : le container nginx s'arrêterait quasi immédiatement après son lancement, alors que le vrai serveur nginx (en arrière-plan) continuerait de tourner un instant, invisible pour Docker.
 
### La solution : `daemon off;`
 
```dockerfile
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```
 
- **`-g`** : passe une directive de configuration globale à nginx en ligne de commande.
- **`daemon off;`** : dit à nginx de **ne pas** se daemoniser — il reste au premier plan.
Résultat : nginx lui-même devient PID 1 du container, reste actif en foreground, et le container reste vivant tant que nginx tourne.
 
### Pourquoi éviter les "hacky patches" (tail -f, sleep infinity, bash)
 
Une mauvaise solution au même problème serait par exemple :
```dockerfile
CMD nginx && tail -f /dev/null
```
Ici, ce n'est plus nginx qui devient PID 1, mais `tail` (ou le shell qui exécute les deux commandes). `tail -f` ne sait pas gérer `SIGTERM`/`SIGQUIT` correctement, ne fait aucun "reaping" de processus enfants — le container devient difficile à arrêter proprement, et le vrai processus utile (nginx) est caché derrière un PID 1 qui ne sert à rien fonctionnellement.
 
### Gestion des signaux : le cas SIGQUIT vs SIGTERM
 
- Par défaut, quand on fait `docker stop`, **Docker envoie SIGTERM** au PID 1, attend 10 secondes (grace period), puis envoie SIGKILL si le processus ne s'est pas arrêté.
- **nginx, lui, utilise SIGQUIT pour un arrêt gracieux** (il termine les requêtes en cours avant de quitter), pas SIGTERM.
→ Sans configuration explicite, nginx recevrait un SIGTERM qu'il gère moins proprement qu'un SIGQUIT.
 
**Solution : préciser le bon signal d'arrêt dans le Dockerfile**
```dockerfile
STOPSIGNAL SIGQUIT
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```
 
### Forme "exec" vs forme "shell" pour CMD/ENTRYPOINT
 
Toujours utiliser la **forme exec** (tableau JSON) plutôt que la forme shell, pour que le processus tourne directement en PID 1 et reçoive les signaux sans intermédiaire :
 
```dockerfile
# ✅ Forme exec — nginx devient directement PID 1
ENTRYPOINT ["nginx", "-g", "daemon off;"]
 
# ❌ Forme shell — un shell intermédiaire devient PID 1,
# nginx tourne en tant qu'enfant et ne reçoit pas les signaux directement
ENTRYPOINT nginx -g "daemon off;"
```
 
### Résumé
 
> "nginx devient PID 1 du container grâce à `daemon off;`, qui l'empêche de se daemoniser et de passer en
arrière-plan. J'utilise la forme exec pour qu'il reçoive directement les signaux Docker, et j'ai précisé `STOPSIGNAL
SIGQUIT` car c'est le signal que nginx attend pour un arrêt gracieux, plutôt que le SIGTERM envoyé par défaut par
Docker."

---
 
## 13. Dockerfile nginx — explication détaillée ligne par ligne
 
### Base image
 
```dockerfile
FROM debian:12.15-slim
```
`-slim` = variante allégée de l'image Debian officielle (moins de paquets préinstallés que l'image standard) → image
de base plus légère, on installe ensuite seulement ce dont on a besoin.
 
### Installation nginx + openssl
 
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```
 
- **`apt-get update`** : met à jour la liste des paquets disponibles (index local), sans installer quoi que ce soit —
nécessaire avant tout `install` pour connaître les dernières versions disponibles dans les dépôts.
- **`apt-get install -y`** : `-y` répond automatiquement "oui" aux confirmations (nécessaire en mode non-interactif,
dans un build Docker il n'y a personne pour taper "y" à la main).
- **`--no-install-recommends`** : évite d'installer les paquets "recommandés" (souvent des extras non essentiels) en
plus des dépendances strictement nécessaires → image plus légère.
- **`nginx`** : le serveur web.
- **`openssl`** : nécessaire pour générer le certificat TLS auto-signé (étape suivante) — pas pour nginx lui-même,
qui a son propre support TLS intégré une fois compilé avec.
- **`apt-get clean`** : vide le cache local des paquets `.deb` téléchargés (dans `/var/cache/apt/archives/`).
- **`rm -rf /var/lib/apt/lists/*`** : supprime les listes d'index de paquets téléchargées par `apt-get update` —
elles ne servent plus une fois l'installation terminée, et representent souvent plusieurs dizaines de Mo.
**Pourquoi tout dans un seul `RUN` avec `&&`** : chaque `RUN` crée une layer Docker. Si le nettoyage (`clean`/`rm`)
était dans un `RUN` séparé, les fichiers supprimés existeraient encore dans la layer précédente (celle de l'install)
→ l'image finale resterait aussi lourde. En groupant tout dans un seul `RUN`, le nettoyage réduit réellement la
taille de la layer finale.
 
### Génération du certificat TLS auto-signé
 
```dockerfile
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=doberes/CN=doberes.42.fr"
```
 
- **`openssl req`** : commande pour créer une demande de certificat (CSR) — ici combinée avec `-x509` pour générer
directement un certificat auto-signé plutôt qu'une simple demande à envoyer à une CA.
- **`-x509`** : indique qu'on veut générer directement un certificat auto-signé (format X.509, le standard des
certificats TLS), au lieu d'une simple requête de signature.
- **`-nodes`** : "no DES" → la clé privée générée ne sera **pas chiffrée par un mot de passe**. Nécessaire ici car le
conteneur doit pouvoir démarrer nginx automatiquement sans qu'un humain tape une passphrase à chaque lancement.
- **`-days 365`** : durée de validité du certificat (1 an). Après cette période, le certificat expirerait et le
navigateur afficherait une erreur de sécurité.
- **`-newkey rsa:2048`** : génère une nouvelle paire de clés RSA de 2048 bits en même temps que la requête (taille
standard, bon compromis sécurité/performance).
- **`-keyout`** : chemin où écrire la clé privée générée.
- **`-out`** : chemin où écrire le certificat public généré.
- **`-subj "/C=.../ST=.../L=.../O=.../OU=.../CN=..."`** : renseigne directement en ligne de commande les informations
du certificat (pays, région, ville, organisation, unité, **CN = Common Name = le nom de domaine couvert par le
certificat**) — évite le mode interactif où openssl poserait ces questions une par une (impossible dans un build
Docker non-interactif).
  - **CN (`doberes.42.fr`) est le champ le plus important** : c'est ce que le navigateur/nginx compare au nom de
domaine demandé pour valider que le certificat correspond bien au site.

### Pourquoi un certificat auto-signé (et pas une vraie CA) ?
 
`doberes.42.fr` n'est pas un vrai domaine public résolvable sur internet — c'est un domaine simulé localement via `
etc/hosts`. Aucune autorité de certification publique (Let's Encrypt, etc.) ne peut/veut délivrer un certificat pour
un domaine qu'elle ne peut pas vérifier publiquement. Un certificat auto-signé est donc la seule option pertinente
ici — le navigateur affichera un avertissement de sécurité (normal et attendu), mais le chiffrement TLS fonctionne
bel et bien.

---

## 14. MariaDB — les 3 fichiers du service

Le service MariaDB repose sur 3 fichiers qui travaillent ensemble : un fichier de config, un script de démarrage, et
le Dockerfile qui assemble le tout.

```
Dockerfile  →  installe MariaDB + copie les 2 fichiers ci-dessous
mariadb.cnf →  configuration du serveur (comment il écoute)
mariadb-script.sh → logique de démarrage (créer la base au 1er lancement, ou juste redémarrer)
```

### 14.1 `mariadb.cnf` — fichier de configuration

```ini
[mysqld]

# Allow connections from any host
bind-address = 0.0.0.0

# Set the default port for MariaDB
port = 3306
```

| Ligne | Rôle |
|---|---|
| `[mysqld]` | Section qui configure le **serveur** MariaDB (par opposition à `[client]` qui configurerait un client
en CLI) |
| `bind-address = 0.0.0.0` | **Le plus important** : par défaut MariaDB n'écoute que sur `127.0.0.1` (localhost),
donc invisible depuis l'extérieur du container. `0.0.0.0` = écoute sur toutes les interfaces réseau → permet à
WordPress (autre container) de s'y connecter via le réseau Docker. Sans ça, aucune connexion externe possible. |
| `port = 3306` | Port standard MySQL/MariaDB. Valeur par défaut, mais notée explicitement pour la lisibilité et pour
montrer que c'est un choix conscient (utile en soutenance). |

Ce fichier est copié dans le Dockerfile vers `/etc/mysql/mariadb.conf.d/60-custom.cnf` — MariaDB charge tous les `
cnf` de ce dossier dans l'ordre alphabétique, donc ce fichier vient s'ajouter à la config par défaut sans l'écraser.

### 14.2 `mariadb-script.sh` — script de démarrage (ENTRYPOINT)

**Rôle global** : au démarrage du container, décider si c'est la **première fois** (créer la base, l'utilisateur,
sécuriser l'install) ou une **relance** (les données existent déjà dans le volume, juste redémarrer normalement).

```bash
#!/bin/bash
set -e
```
`set -e` : arrête le script immédiatement si une commande échoue. Évite de continuer avec une base à moitié
configurée en cas d'erreur.

```bash
if [ -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    echo "INFO: La base de données existe déjà. Démarrage direct..."
else
    echo "INFO: Première installation de MariaDB. Configuration en cours..."
```
**Le cœur de la logique** : vérifie si le dossier de la base existe déjà dans `/var/lib/mysql` (monté en **volume
persistant**). Sans cette vérification, chaque redémarrage du container réinitialiserait la base et perdrait toutes
les données (articles WordPress, comptes utilisateurs, etc.).

```bash
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
```
Initialise les tables système internes de MariaDB (gestion des users/permissions — pas encore la base applicative).
`--user=mysql` : exécuté avec l'utilisateur système `mysql`, pas root (bonne pratique). `> /dev/null` masque la
sortie verbeuse.

```bash
    mysqld_safe --datadir=/var/lib/mysql --user=mysql &
```
Démarre MariaDB **en arrière-plan temporaire** (`&`) — nécessaire pour pouvoir exécuter des commandes SQL dessus
juste après (avant le vrai démarrage définitif en fin de script).

```bash
    until mysqladmin ping --silent; do
        echo "En attente de MariaDB..."
        sleep 1
    done
```
**Attente active (polling)** : teste toutes les secondes si le serveur répond, avant de continuer. Le serveur lancé
juste avant met un peu de temps à être prêt — sans cette attente, la commande SQL suivante échouerait en se
connectant trop tôt.

```bash
    mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
```
Syntaxe **heredoc** : envoie tout ce bloc comme des commandes SQL au client `mariadb`, connecté en root (sans mot de
passe à ce stade). Détail de chaque commande :
- `ALTER USER root ...` : définit le mot de passe root, depuis une **variable d'environnement** (`.env`), jamais en
dur dans le code
- `DELETE FROM mysql.user WHERE User=''` : supprime les comptes "anonymes" créés par défaut (durcissement sécurité)
- `DROP DATABASE test` : supprime la base `test` par défaut, accessible sans authentification stricte
- `CREATE DATABASE ...` : crée la vraie base applicative pour WordPress
- `CREATE USER ... @'%' ...` : crée un utilisateur **dédié** (pas root) pour WordPress. Le `@'%'` autorise la
connexion depuis n'importe quelle IP — nécessaire car WordPress se connecte depuis un **autre container**
- `GRANT ALL PRIVILEGES ON db.*` : donne tous les droits à cet utilisateur, mais **uniquement sur cette base
précise** (principe de moindre privilège, pas un accès root global)
- `FLUSH PRIVILEGES` : recharge les tables de permissions pour appliquer les changements immédiatement

```bash
    mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
    wait
```
Arrête proprement l'instance temporaire. `wait` attend que le process en arrière-plan soit vraiment terminé avant de
continuer, pour éviter un conflit avec le démarrage définitif juste après.

```bash
fi

exec mysqld_safe --datadir=/var/lib/mysql --user=mysql
```
**Le vrai démarrage, en premier plan cette fois.** `exec` remplace le process du script bash par celui de
`mysqld_safe` — important pour le PID 1 : ça permet à MariaDB de recevoir directement les signaux Docker (`SIGTERM` à
l'arrêt), garantissant un arrêt propre du container.

### 14.3 `Dockerfile` — assemblage

```dockerfile
RUN apt-get install -y --no-install-recommends \
    mariadb-server \
    mariadb-client \
    procps
```
- `mariadb-server` : le serveur lui-même
- `mariadb-client` : nécessaire pour exécuter les commandes SQL du script (`mariadb -u root ...`)
- `procps` : utilitaires système (comme `ps`) parfois requis en interne par `mysqld_safe` pour surveiller les process
— sans ce paquet, certains scripts internes de MariaDB peuvent échouer silencieusement

```dockerfile
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld
```
Crée le dossier où MariaDB place son socket Unix et son fichier PID, avec les bonnes permissions pour l'utilisateur
système `mysql`. Sans ça, le serveur planterait au démarrage, incapable d'écrire ses fichiers de contrôle.

```dockerfile
COPY ./conf/mariadb.cnf /etc/mysql/mariadb.conf.d/60-custom.cnf
```
Le "60" dans le nom permet de contrôler l'ordre de priorité si plusieurs fichiers `.cnf` coexistent dans ce dossier
(chargés par ordre alphabétique).

```dockerfile
ENTRYPOINT ["/usr/local/bin/mariadb-script.sh"]
```
Le script devient le point d'entrée : il décide à chaque démarrage s'il faut initialiser une nouvelle base ou
relancer sur des données existantes.

### 14.4 Vocabulaire — `mysqld` vs `mysqld_safe` vs `mysqladmin`

Trois commandes qui reviennent souvent dans les scripts MariaDB, à ne pas confondre :

| Commande | Rôle |
|---|---|
| `mysqld` | Le **daemon** MySQL/MariaDB lui-même ("MySQL Daemon") — le vrai processus serveur qui tourne en continu : reçoit les connexions, exécute les requêtes SQL, lit/écrit les données sur disque |
| `mysqld_safe` | Un **wrapper** autour de `mysqld` — le lance, surveille s'il crash, le relance automatiquement si besoin, écrit des logs d'erreurs. Couche de sécurité/supervision autour du process brut |
| `mysqladmin` | Un outil **client** en ligne de commande pour administrer un serveur déjà lancé (ping, shutdown, status...) — ne lance rien lui-même, communique avec un `mysqld` déjà actif |

**Analogie simple**
- `mysqld` = le restaurant qui a ouvert ses portes et sert les clients
- `mysqld_safe` = le gérant qui s'assure que le restaurant reste ouvert, et le rouvre s'il ferme accidentellement
- `mysqladmin` = un client qui appelle pour demander "êtes-vous ouverts ?" avant de s'y rendre

**Dans mon script, ces 3 apparaissent à des moments différents :**
```bash
mysqld_safe --datadir=/var/lib/mysql --user=mysql &
```
Lance le serveur via le wrapper (plus robuste qu'un `mysqld` direct, gère mieux les erreurs de démarrage).

```bash
until mysqladmin ping --silent; do
```
Le client `mysqladmin` teste si `mysqld` (lancé juste avant) répond déjà — sert de signal pour savoir que le serveur est prêt à accepter des connexions.

```bash
exec mysqld_safe --datadir=/var/lib/mysql --user=mysql
```
Démarrage définitif, toujours via le wrapper — cohérent avec le premier lancement temporaire.

**Note** : certains Dockerfiles trouvés sur GitHub utilisent `mysqld` directement en `CMD` (`CMD ["mysqld", "--bind-address=0.0.0.0"]`), sans passer par `mysqld_safe` — plus simple et direct, mais moins de supervision automatique en cas de crash du process.

### 14.5 Comparatif — bonnes vs mauvaises pratiques observées ailleurs

En comparant avec d'autres implémentations trouvées sur GitHub (anciens élèves 42), quelques pièges à ne jamais reproduire :

| ❌ À éviter (vu ailleurs) | ✅ Bonne pratique (fait chez moi) |
|---|---|
| Mot de passe en dur dans le script (`root4life`) | Mots de passe via variables d'environnement (`.env`) |
| `GRANT ALL ON *.*` pour root en accès distant (`@'%'`) | Utilisateur dédié avec droits limités à une seule base |
| `user = root` dans la conf MariaDB (process tourne en root) | Process lancé via l'utilisateur système `mysql` |
| `debian:buster` (Debian 10, obsolète, fin de support) | `debian:12.15-slim` (Bookworm, avant-dernière stable) |

**Piste d'amélioration possible** : ajouter `USER mysql` en fin de Dockerfile (avant l'`ENTRYPOINT`) pour que le process tourne en non-root — actuellement il tourne en root par défaut. À tester avant d'appliquer, car `mysql_install_db` pourrait nécessiter des droits root au tout premier lancement.

### 14.6 MariaDB — fork de MySQL et multi-threading

MariaDB est un **fork** de MySQL (créé par les développeurs originaux de MySQL après le rachat par Oracle, pour garder un projet 100% open source).

**Avantage multi-threading** : MariaDB gère mieux le multi-threading que MySQL sur plusieurs aspects (thread pooling plus efficace, réplication multi-threadée) — utile pour encaisser des pics de trafic sur le site, puisque plusieurs requêtes peuvent être traitées en parallèle plus efficacement plutôt que de se bloquer les unes les autres.

---

## 15. Vue d'ensemble — répartition des rôles dans Inception

Pour garder une vue claire du "qui fait quoi" entre les 3 services obligatoires :

| Service | Rôle principal |
|---|---|
| **Nginx** | Point d'entrée unique de l'infrastructure — reçoit tout le trafic HTTPS, gère le TLS, fait office de reverse proxy vers WordPress |
| **WordPress (+ php-fpm)** | Exécute le code applicatif — les fichiers PHP, templates de thème (structure/style des pages), logique métier. Les fichiers du thème/plugins sont souvent stockés en volume pour persister |
| **MariaDB** | Stocke les données : contenu des articles/pages, comptes utilisateurs, permissions, et une partie des réglages/options du thème |

⚠️ **Petite nuance à garder en tête** : la séparation "structure/style = WordPress" vs "contenu/users = MariaDB" est une bonne image mentale, mais pas totalement étanche — certains réglages de thème (couleurs, mise en page personnalisée via l'éditeur WordPress) sont aussi stockés en base de données, pas uniquement dans les fichiers PHP/CSS. La distinction plus précise serait : **fichiers de code (thème, plugins, logique)** vs **données stockées en base (contenu, comptes, une partie des options)**.

**Pourquoi cette séparation protège les données**
En cas de crash ou de recréation d'un container, chaque service repart de son image de base, mais les **volumes persistants** (MariaDB + WordPress) gardent les vraies données. Ça permet par exemple de reconstruire le container Nginx sans rien perdre côté contenu du site — la donnée ne dépend pas du cycle de vie du container qui la sert.

---

## 16. Vidéos / sources vues

- [ ] TechWorld with Nana — Docker Crash Course For Absolute Beginners
- Youssef medium 
- [ ] https://medium.com/@mvuk/using-tls-certificates-with-nginx-docker-container-74c6769a26db
- [ ] https://docs.docker.com/build/building/best-practices/
- [ ] https://medium.com/@imyzf/inception-3979046d90a0
- [ ] https://medium.com/@mvuk/using-tls-certificates-with-nginx-docker-container-74c6769a26db
- [ ] https://docs.nginx.com/nginx/admin-guide/basic-functionality/runtime-control/
- [ ] https://labex.io/questions/what-is-the-purpose-of-the-nginx-g-daemon-off-command-in--871954