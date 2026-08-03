Configurer la DNS local
check nano : which nano
en mode root : sudo nano /etc/hosts
127.0.0.1       localhost
127.0.1.1       doberes

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.0.1       doberes.42.fr (ajouter)

check : ping -c 2 doberes.42.fr

DNS (Domain Name Server) -> annuaireninternet -> traduit google>com en une adresse ip

DNS local (carnet d'adresse de la machine) -> avant d'aller sur le net, l'rdinateur regarde d'abord dans son fichier /etc/hosts
127.0.0.1 doberes.42.fr -> ne va pas sur le net, pointe vers moi-meme (permet de tester le site web comme si ell etait en ligne)

ping -> sonar reseau -> permet de savoir si une autre machine reponde et a quelle vitesse
ping -c 2 doberes.42.fr
l'ordinateur envoie 2 paquets de donnees a l'adresse doberes.42.fr et attend le retour

doberes@doberes:~$ ping -c 2 doberes.42.fr
PING doberes.42.fr (127.0.0.1) 56(84) bytes of data. (machine pointe vers elle-meme)
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.167 ms
64 bytes from localhost (127.0.0.1): icmp_seq=2 ttl=64 time=0.036 ms

--- doberes.42.fr ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.036/0.101/0.167/0.065 ms


sur le pc hote
sudo nano /etc/hosts
192.168.64.3 doberes.42.fr (ajouter)


eteindre la vm
sudo shutdown -h now

rallumer dans UTM et relancer
login et mp intra42
ip a -> ligne inet
ip pour ssh -> 192.168.64.3
ssh doberes@192.168.64.3