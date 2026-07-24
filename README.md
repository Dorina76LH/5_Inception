*This project has been created as part of the 42 curriculum by <doberes>.*
 
## Description
 
<!-- Present the project clearly: what is Inception, its goal, brief overview of the infrastructure -->
 
## Instructions
 
<!-- Compilation / installation / execution: how to clone, configure secrets & .env, and run the project via the Makefile -->
 
## Project description
 
<!-- Explain the use of Docker and the sources included in the project. Indicate the main design choices. -->
 
### Virtual Machines vs Docker
 
<!-- Comparison -->
 
### Secrets vs Environment Variables
 
<!-- Comparison -->
 
### Docker Network vs Host Network
 
<!-- Comparison -->
 
### Docker Volumes vs Bind Mounts
 
<!-- Comparison -->
 
## Resources
 
<!-- Classic references: official docs, articles, tutorials -->
 
<!-- AI usage: specify for which tasks and which parts of the project AI was used -->

# Test de push depuis ma VM

🏗️ 1. L'infrastructure : La VM avec UTM
Ce qui a été fait : Tu as installé une Machine Virtuelle (VM) Debian (architecture arm64v8) sur ton Mac en utilisant UTM.
La configuration des droits (sudo) : Lors de l'installation, tu as volontairement laissé le mot de passe du compte root (l'administrateur suprême) vide. Sous Debian, cela a une conséquence très précise et super pratique : le système n'active pas le compte root classique, mais il donne automatiquement les privilèges d'administration (sudo) à ton utilisateur principal (doberes). Ton utilisateur hérite donc des droits pour installer tout ce qu'il veut avec son propre mot de passe.
L'accès à distance : Tu as configuré le réseau pour pouvoir te connecter à ta VM directement depuis le terminal de ton Mac via la commande :
ssh doberes@192.168.64.3
Cela t'évite de devoir utiliser la petite fenêtre UTM moins pratique (pas de copier-coller, etc.).

🛠️ 2. Les outils installés dans la VM
Tu as mis à jour le système et installé la boîte à outils essentielle pour ton projet 42 :
Git (pour cloner et gérer ton code).
Curl & Make (pour automatiser tes compilations via le Makefile).
Docker & Docker Compose (Le moteur officiel, récupéré directement sur le dépôt officiel Docker).
Le test ultime : Tu as lancé sudo docker run hello-world, et Docker a répondu parfaitement. Le moteur est 100% opérationnel !

🔑 3. L'authentification SSH (GitHub / Vogsphere)
Pour pouvoir échanger avec GitHub sans taper ton mot de passe à chaque fois (ce que GitHub bloque de toute façon), nous avons configuré une clé de sécurité moderne :
Algorithme utilisé : ED25519 (le standard actuel : ultra-sécurisé, rapide et avec des clés très courtes, faciles à copier-coller).
Le flux : Tu as généré cette clé dans la VM via ssh-keygen -t ed25519, récupéré sa version publique avec cat ~/.ssh/id_ed25519.pub, et tu l'as enregistrée dans les paramètres de ton compte GitHub.
La configuration Git : Tu as configuré ton identité globale sur la VM (user.name et user.email) pour que tes futurs commits soient bien attribués à ton compte.

🔄 4. Le Workflow actuel (Ton plan de travail)
Pour l'instant, tu as validé le flux classique :
Tu ouvres ton projet localement sur ton Mac.
Tu codes confortablement dans ton VS Code sur Mac.
Tu fais tes git add / commit / push depuis ton Mac vers GitHub.
Dans le terminal de ta VM (connecté en SSH), tu fais un git pull pour récupérer ton code et le tester avec Docker.

🏁 5. Ce qu'il reste à régler : Le cas VS Code Remote
Hier soir, on a tenté d'activer l'extension VS Code Remote - SSH pour que ton VS Code se connecte directement dans la VM (ce qui t'éviterait de faire des push/pull incessants juste pour tester une ligne de code).
Tu t'es heurté à un message Permission denied. C'est le petit point technique qu'il nous reste à débloquer aujourd'hui si tu veux gagner en fluidité.
Tu as une configuration ultra propre pour attaquer Inception. Est-ce que tu veux qu'on commence par régler ce problème de Permission denied sur VS Code pour te simplifier la vie, ou préfères-tu qu'on attaque directement l'architecture des fichiers Docker ?

eyaindre la vm
sudo shutdown -h now

rallumer dans UTM et relancer
ssh doberes@192.168.64.3

# Notes Inception — Setup VM

## 1. Avant l'installation

- [ ] Télécharger l'ISO **Debian ARM64** (netinst, pas la version desktop complète) — adapté au Mac M3 (Apple Silicon)
- [ ] Créer la VM dans UTM :
  - Réseau en mode **Bridged** (pas NAT) → la VM aura sa propre IP sur le réseau local, plus simple pour SSH et tests
  - RAM et disque : taille minimale (ex. 2 Go RAM / 8-10 Go disque suffisent pour Inception)
  - **Pas de partition** custom → laisser le partitionnement automatique/guidé

## 2. Pendant l'installation Debian

- [ ] Fuseau horaire / clavier (fr)
- [ ] Créer un utilisateur (pas root direct)
- [ ] **Ne pas installer d'environnement de bureau** (Desktop environment) → décocher dans le choix des tâches
- [ ] Cocher uniquement :
  - `SSH server`
  - `standard system utilities`
- [ ] Pas de sudo par défaut → configurer ensuite l'utilisateur dans le groupe sudo

```bash
# Ajouter son user au groupe sudo (à faire en root ou via su)
usermod -aG sudo ton_user
```

## 3. Après l'installation — paquets à installer

```bash
sudo apt update && sudo apt upgrade -y

# Git
sudo apt install -y git

# Docker + Docker Compose
sudo apt install -y docker.io docker-compose

# SSH server (si pas fait à l'install)
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

**Éviter d'avoir à taper `sudo` avant chaque commande docker :**
```bash
sudo usermod -aG docker $USER
# puis se déconnecter/reconnecter (ou reboot) pour que ça prenne effet
```

## 4. Initialiser Git (clé SSH)

```bash
# Générer une paire de clés SSH
ssh-keygen -t ed25519 -C "ton_email@exemple.com"

# Afficher la clé publique pour la copier
cat ~/.ssh/id_ed25519.pub
```
→ Copier la clé affichée, l'ajouter sur GitHub/GitLab : **Settings > SSH and GPG keys > New SSH key**

```bash
# Tester la connexion
ssh -T git@github.com
```

## 5. Récupérer l'adresse IP de la VM

```bash
ip a
# ou
hostname -I
```
→ Repérer l'IP sur l'interface réseau principale (souvent `enp0sX` ou similaire, pas `lo`)

## 6. Se connecter en SSH depuis le Mac

```bash
ssh ton_user@IP_DE_LA_VM
```

## 7. Cloner le dépôt Inception

```bash
git clone git@github.com:ton_compte/inception.git
cd inception
```

## 8. Configurer `/etc/hosts` (sur le Mac, PAS dans la VM)

```bash
sudo nano /etc/hosts
```
Ajouter la ligne :
```
IP_DE_LA_VM    login.42.fr
```
(remplacer `login` par ton vrai login 42)

## 9. Bonus / bonnes pratiques à ne pas oublier

- [ ] Faire un **snapshot UTM** une fois la base propre installée (Debian + Docker + Git configurés) → restauration rapide en cas de casse
- [ ] Vérifier `docker --version` et `docker-compose --version` fonctionnent sans erreur
- [ ] Tester `docker run hello-world` pour valider l'install Docker
- [ ] Noter la version exacte de Debian utilisée (ex. `12.15`) pour la cohérence avec les Dockerfiles

## 10. Vérifications finales avant de coder

```bash
# Version Debian installée
cat /etc/debian_version

# Version Docker
docker --version
docker-compose --version

# Test hello-world
docker run hello-world
```