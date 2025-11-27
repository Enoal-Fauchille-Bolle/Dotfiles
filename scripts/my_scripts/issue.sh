#!/bin/bash

SOURCE_REPO="EpitechPromo2028/B-DOP-400-NAN-4-1-octopus-evan.mahe"
TARGET_REPO="Enoal-Fauchille-Bolle/Octopus"

# Liste des issues ouvertes dans le dépôt source avec plus de données
issues=$(gh issue list -R "$SOURCE_REPO" --state all --json number,title,body,labels,state,assignees,milestone)

# Boucle sur chaque issue
echo "$issues" | jq -c '.[]' | while read -r issue; do
    number=$(echo "$issue" | jq -r '.number')
    title=$(echo "$issue" | jq -r '.title')
    body=$(echo "$issue" | jq -r '.body')
    labels=$(echo "$issue" | jq -r '.labels | map(.name) | join(",")')
    state=$(echo "$issue" | jq -r '.state')
    assignees=$(echo "$issue" | jq -r '.assignees | map(.login) | join(",")')
    milestone=$(echo "$issue" | jq -r '.milestone.title // empty')

    echo "Processing issue #$number: $title"
    echo "Body: $body"
    echo "Labels: $labels"
    echo "State: $state"
    echo "Assignees: $assignees"
    echo "Milestone: $milestone"

    # Préparer les options pour la création de l'issue
    create_opts="-R $TARGET_REPO --title \"$title\" --body \"$body\""

    # Ajouter les labels s'ils existent
    if [ -n "$labels" ]; then
        create_opts="$create_opts --label \"$labels\""
    fi

    # Ajouter les assignees s'ils existent
    if [ -n "$assignees" ]; then
        create_opts="$create_opts --assignee \"$assignees\""
    fi

    # Ajouter le milestone s'il existe
    if [ -n "$milestone" ]; then
        create_opts="$create_opts --milestone \"$milestone\""
    fi

    echo "Creating issue with options: $create_opts"

    # Création de l'issue dans le dépôt cible
    eval "gh issue create $create_opts"

    # # Si l'issue était fermée dans le source, la fermer dans le target
    if [ "$state" = "CLOSED" ]; then
        # Obtenir le numéro de la dernière issue créée
        last_issue=$(gh issue list -R "$TARGET_REPO" --limit 1 --json number | jq -r '.[0].number')
        echo "Closing issue #$last_issue as it was closed in source"
        gh issue close -R "$TARGET_REPO" "$last_issue"
    fi

    echo "---"
done
