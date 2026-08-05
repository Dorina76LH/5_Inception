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

## 11. Vidéos / sources vues

- [ ] TechWorld with Nana — Docker Crash Course For Absolute Beginners
- Youssef medium 
- [ ] https://medium.com/@mvuk/using-tls-certificates-with-nginx-docker-container-74c6769a26db