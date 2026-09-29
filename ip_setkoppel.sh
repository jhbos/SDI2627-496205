#!/bin/bash

echo "=========================================="
echo " Proxmox IP-Set Koppelen"
echo "=========================================="
echo ""

if [[ "$EUID" -ne 0 ]]; then
    echo "FOUT: voer dit script uit als root."
    exit 1
fi

if ! command -v pvesh >/dev/null 2>&1; then
    echo "FOUT: pvesh is niet beschikbaar."
    echo "Voer dit script uit op een Proxmox-host."
    exit 1
fi

while true; do
    read -r -p "Voer de NAAM van de IP-Set in: " IPSET_NAME
    read -r -p "Voer het IP-ADRES in voor '$IPSET_NAME': " IP_ADDRESS

    # IP-setnamen automatisch naar kleine letters omzetten
    IPSET_NAME="${IPSET_NAME,,}"

    if [[ -z "$IPSET_NAME" || -z "$IP_ADDRESS" ]]; then
        echo "FOUT: naam en IP-adres mogen niet leeg zijn."
        echo ""
        continue
    fi

    if [[ ! "$IPSET_NAME" =~ ^[a-z0-9_-]+$ ]]; then
        echo "FOUT: gebruik alleen letters, cijfers, - en _ in de IP-setnaam."
        echo ""
        continue
    fi

    if [[ ! "$IP_ADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
        echo "FOUT: gebruik bijvoorbeeld 10.24.20.124 of 10.24.20.124/32."
        echo ""
        continue
    fi

    # Een enkel IP-adres wordt automatisch /32
    if [[ "$IP_ADDRESS" != */* ]]; then
        IP_ADDRESS="${IP_ADDRESS}/32"
    fi

    echo ""
    echo "Bezig met IP-set '$IPSET_NAME'..."

    # Controleer of de IP-set al bestaat
    if pvesh get "/cluster/firewall/ipset/$IPSET_NAME" >/dev/null 2>&1; then
        echo "IP-set '$IPSET_NAME' bestaat al."
    else
        echo "IP-set '$IPSET_NAME' bestaat nog niet. Aanmaken..."

        if ! pvesh create /cluster/firewall/ipset --name "$IPSET_NAME"; then
            echo "FOUT: IP-set '$IPSET_NAME' kon niet worden aangemaakt."
            echo ""
            continue
        fi

        echo "IP-set '$IPSET_NAME' is aangemaakt."

        # Even wachten op synchronisatie van de clusterconfiguratie
        sleep 2
    fi

    echo "IP-adres '$IP_ADDRESS' toevoegen..."

    if pvesh create "/cluster/firewall/ipset/$IPSET_NAME" --cidr "$IP_ADDRESS"; then
        echo "IP '$IP_ADDRESS' is succesvol toegevoegd aan IP-set '$IPSET_NAME'."
    else
        echo "FOUT: IP '$IP_ADDRESS' kon niet worden toegevoegd."
    fi

    echo ""

    read -r -p "Wil je nog een IP-set koppelen? (j/n): " ANTWOORD

    if [[ "$ANTWOORD" != "j" && "$ANTWOORD" != "J" ]]; then
        echo ""
        echo "Klaar! Het script is afgesloten."
        break
    fi

    echo ""
    echo "------------------------------------------"
done

# Veel gezijk doordat het case setive is