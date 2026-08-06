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

## 14. Vidéos / sources vues

- [ ] TechWorld with Nana — Docker Crash Course For Absolute Beginners
- Youssef medium 
- [ ] https://medium.com/@mvuk/using-tls-certificates-with-nginx-docker-container-74c6769a26db
- [ ] https://docs.docker.com/build/building/best-practices/
- [ ] https://medium.com/@imyzf/inception-3979046d90a0
- [ ] https://medium.com/@mvuk/using-tls-certificates-with-nginx-docker-container-74c6769a26db
- [ ] https://docs.nginx.com/nginx/admin-guide/basic-functionality/runtime-control/
- [ ] https://labex.io/questions/what-is-the-purpose-of-the-nginx-g-daemon-off-command-in--871954