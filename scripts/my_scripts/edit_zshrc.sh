#!/bin/bash

FILE="$HOME/Dotfiles/zsh/.zshrc"

# Fonction pour quitter proprement
quit() {
    if sudo -n true 2>/dev/null; then
        # Si on a encore les droits sudo, reverrouiller sans redemander
        echo ""
        echo "Re-locking the file..."
        sudo chattr +i "$FILE"
        echo "File .zshrc is now locked."
        exit
    else
        echo "Sudo privileges expired or not granted. Exiting."
        exit 1
    fi
}

lock () {
    if sudo -n true 2>/dev/null; then
        # Si on a encore les droits sudo, reverrouiller sans redemander
        echo "Re-locking the file..."
        sudo chattr +i "$FILE"
        echo "File .zshrc is now locked."
        exit
    else
        # Sinon, demander les droits sudo
        echo "Sudo privileges are required to lock the file."
        if sudo -n true 2>/dev/null; then
            # Reverrouiller si les droits sudo sont accordés
            echo "Re-locking the file..."
            sudo chattr +i "$FILE"
            echo "File .zshrc is now locked."
            exit
        else
            # Sinon, quitter
            echo "File kept unlocked."
            quit
        fi
    fi
}

# Gestion des interruptions (Ctrl+C)
trap quit INT

# Gestion des erreurs
trap lock ERR TERM

# Déverrouiller le fichier
if sudo chattr -i "$FILE"; then
    echo "File .zshrc is now unlocked."
else
    echo "Error: Failed to unlock .zshrc. Exiting."
    exit 1
fi

# Ouvrir .zshrc dans VS Code
# Ouvrir .zshrc dans VS Code
if ! code "$FILE"; then
    echo "Error: Failed to open .zshrc in VS Code."
    lock
fi

# Attendre que l'utilisateur appuie sur Entrée pour continuer
read -p "Press Enter to lock the file and close VS Code..."

# Reverrouiller le fichier
sudo chattr +i "$FILE"
echo "File .zshrc is now locked."

