#!/bin/bash

# Configureer de IP-adressen van de agents
agent1=192.168.100.212
agent2=192.168.100.222
agent3=192.168.100.232

# Gebruikersnaam van de nodes
user=k3s

# Array van agents
agents=($agent1 $agent2 $agent3)

# SSH-sleutel
ssh_key="~/.ssh/id_rsa"

# Controleer of SSH toegang werkt
check_ssh() {
    for node in "${agents[@]}"; do
        echo "Controleer verbinding met $node..."
        ssh -i $ssh_key $user@$node "echo 'Verbonden met $node!'"
        if [ $? -ne 0 ]; then
            echo "Kan geen verbinding maken met $node. Controleer SSH-sleutels."
            exit 1
        fi
    done
}

# Formatteer en mount /dev/sdb op agents
setup_storage() {
    for node in "${agents[@]}"; do
        echo "Instellen van storage op $node..."
        ssh -i $ssh_key $user@$node <<EOF
            if lsblk | grep -q 'sdb'; then
                sudo mkfs.ext4 -F /dev/sdb
                sudo mkdir -p /mnt/longhorn
                sudo mount /dev/sdb /mnt/longhorn
                echo '/dev/sdb /mnt/longhorn ext4 defaults 0 2' | sudo tee -a /etc/fstab
                echo "Storage succesvol ingesteld op $node."
            else
                echo "/dev/sdb niet gevonden op $node!"
            fi
EOF
    done
}

# Installeer Longhorn op het cluster
install_longhorn() {
    echo "Installeer Longhorn op het cluster..."
    kubectl create namespace longhorn-system
    helm repo add longhorn https://charts.longhorn.io
    helm repo update
    helm install longhorn longhorn/longhorn --namespace longhorn-system
    echo "Longhorn installatie voltooid!"
}

# Controleer de status van Longhorn
verify_longhorn() {
    echo "Controleren of Longhorn correct is geïnstalleerd..."
    kubectl -n longhorn-system get pods
}

# Hoofdfunctie
main() {
    echo "Start configuratie..."
    check_ssh
    setup_storage
    install_longhorn
    verify_longhorn
    echo "Setup voltooid!"
}

# Script starten
main
