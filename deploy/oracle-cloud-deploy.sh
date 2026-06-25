#!/bin/bash
# =============================================================================
# Oracle Cloud Infrastructure — Avtomaticheskoye razvertyvaniye MARIA-sayta
# Posle registratsii na https://signup.oraclecloud.com/ zapustite etot skript
# =============================================================================

set -euo pipefail

# --- Konfiguratsiya ---
APP_NAME="maria-site"
DOMAIN="maria-site.duckdns.org"
REGION="eu-frankfurt-1"          # ili eu-amsterdam-1, uk-london-1
SHAPE="VM.Standard.A1.Flex"      # Besplatnyy ARM64 (4 OCPU, 24 GB RAM)
OCPU_COUNT=4
MEMORY_GB=24
BOOT_VOLUME_GB=200
SSH_KEY="$HOME/.ssh/id_rsa.pub"  # Dolzhen suschestvovat!

# --- Tsveta ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

# --- Proverka zavisimostey ---
check_deps() {
    command -v oci >/dev/null 2>&1 || err "OCI CLI ne ustanovlen. Ustanovite: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm"
    command -v ssh-keygen >/dev/null 2>&1 || err "ssh-keygen ne nayden"
    [ -f "$SSH_KEY" ] || ssh-keygen -t rsa -b 4096 -f "${SSH_KEY%.pub}" -N ""
    log "Zavisimosti provereny"
}

# --- Sozdaniye VCN i seti ---
create_network() {
    log "Sozdaniye VCN..."
    VCN_ID=$(oci network vcn create \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "${APP_NAME}-vcn" \
        --cidr-block "10.0.0.0/16" \
        --query 'data.id' --raw-output 2>/dev/null) || {
        VCN_ID=$(oci network vcn list --compartment-id "$COMPARTMENT_ID" \
            --query "data[?\"display-name\"=='${APP_NAME}-vcn'].id | [0]" --raw-output)
    }
    log "VCN: $VCN_ID"

    # Internet Gateway
    IG_ID=$(oci network internet-gateway create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${APP_NAME}-ig" \
        --is-enabled true \
        --query 'data.id' --raw-output 2>/dev/null) || {
        IG_ID=$(oci network internet-gateway list --compartment-id "$COMPARTMENT_ID" \
            --vcn-id "$VCN_ID" --query "data[?\"display-name\"=='${APP_NAME}-ig'].id | [0]" --raw-output)
    }

    # Route Table
    RT_ID=$(oci network route-table list --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" --query "data[0].id" --raw-output)
    oci network route-table update --rt-id "$RT_ID" --route-rules "[{'destination':'0.0.0.0/0','destinationType':'CIDR_BLOCK','networkEntityId':'$IG_ID'}]" --force >/dev/null

    # Security List (porty)
    SEC_LIST_ID=$(oci network security-list list --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" --query "data[0].id" --raw-output)
    oci network security-list update --security-list-id "$SEC_LIST_ID" \
        --ingress-security-rules "[
            {'source':'0.0.0.0/0','protocol':'6','tcpOptions':{'destinationPortRange':{'min':22,'max':22}}},
            {'source':'0.0.0.0/0','protocol':'6','tcpOptions':{'destinationPortRange':{'min':80,'max':80}}},
            {'source':'0.0.0.0/0','protocol':'6','tcpOptions':{'destinationPortRange':{'min':443,'max':443}}}
        ]" --force >/dev/null

    # Subnet
    SUBNET_ID=$(oci network subnet create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${APP_NAME}-subnet" \
        --cidr-block "10.0.1.0/24" \
        --availability-domain "$(oci iam availability-domain list --query 'data[0].name' --raw-output)" \
        --query 'data.id' --raw-output 2>/dev/null) || {
        SUBNET_ID=$(oci network subnet list --compartment-id "$COMPARTMENT_ID" \
            --vcn-id "$VCN_ID" --query "data[?\"display-name\"=='${APP_NAME}-subnet'].id | [0]" --raw-output)
    }
    log "Subnet: $SUBNET_ID"
    echo "$SUBNET_ID" > /tmp/maria-subnet.id
}

# --- Sozdaniye VM ---
create_instance() {
    SUBNET_ID=$(cat /tmp/maria-subnet.id)
    IMAGE_ID=$(oci compute image list --compartment-id "$COMPARTMENT_ID" \
        --operating-system "Canonical Ubuntu" --operating-system-version "22.04" \
        --shape "$SHAPE" --query "data[?\"display-name\"=='Canonical-Ubuntu-22.04-Minimal-aarch64-*'].id | [0]" --raw-output)

    log "Sozdaniye VM ($SHAPE, $OCPU_COUNT OCPU, $MEMORY_GB GB RAM)..."
    INSTANCE_ID=$(oci compute instance launch \
        --compartment-id "$COMPARTMENT_ID" \
        --availability-domain "$(oci iam availability-domain list --query 'data[0].name' --raw-output)" \
        --display-name "$APP_NAME" \
        --shape "$SHAPE" \
        --shape-config "{\"ocpus\":$OCPU_COUNT,\"memoryInGBs\":$MEMORY_GB}" \
        --image-id "$IMAGE_ID" \
        --subnet-id "$SUBNET_ID" \
        --ssh-authorized-keys-file "$SSH_KEY" \
        --boot-volume-size-in-gbs "$BOOT_VOLUME_GB" \
        --query 'data.id' --raw-output)
    log "VM sozdana: $INSTANCE_ID"
    echo "$INSTANCE_ID" > /tmp/maria-instance.id

    # Zhdem publichnogo IP
    log "Ozhidaniye publichnogo IP..."
    for i in {1..30}; do
        PUBLIC_IP=$(oci compute instance list-vnics --instance-id "$INSTANCE_ID" \
            --query 'data[0].\"public-ip\"' --raw-output 2>/dev/null || true)
        [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ] && break
        sleep 10
    done
    [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "null" ] && err "Ne udalos poluchit publichniy IP"
    log "Publichniy IP: $PUBLIC_IP"
    echo "$PUBLIC_IP" > /tmp/maria-public.ip
}

# --- Ustanovka Docker i deploy sayta ---
deploy_app() {
    PUBLIC_IP=$(cat /tmp/maria-public.ip)
    SSH_KEY_PRIV="${SSH_KEY%.pub}"

    log "Ozhidaniye SSH (mozhet zanyat 2-3 minuty)..."
    for i in {1..30}; do
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$SSH_KEY_PRIV" "ubuntu@$PUBLIC_IP" "echo OK" 2>/dev/null && break
        sleep 10
    done

    log "Ustanovka Docker..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PRIV" "ubuntu@$PUBLIC_IP" <<'REMOTE'
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose git nginx certbot
        sudo usermod -aG docker ubuntu
        sudo systemctl enable docker
        sudo systemctl start docker
REMOTE

    log "Klonirovaniye repozitoriya..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PRIV" "ubuntu@$PUBLIC_IP" \
        "git clone https://github.com/Serg2206/maria-site.git /home/ubuntu/maria-site"

    log "Zapusk Nginx..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PRIV" "ubuntu@$PUBLIC_IP" <<REMOTE
        sudo docker run -d --name nginx -p 80:80 -v /home/ubuntu/maria-site/public:/usr/share/nginx/html:ro nginx:alpine
REMOTE

    log "=========================================="
    log "Sayt dostupen: http://$PUBLIC_IP"
    log "Repozitoriy:   /home/ubuntu/maria-site"
    log "SSH:           ssh -i $SSH_KEY_PRIV ubuntu@$PUBLIC_IP"
    log "=========================================="
    log "Teper nastroite DuckDNS: $DOMAIN -> $PUBLIC_IP"
    log "I poluchite SSL: sudo certbot --nginx -d $DOMAIN"
}

# --- Glavnoye menyu ---
main() {
    echo "=========================================="
    echo "  Oracle Cloud Deploy: MARIA-site"
    echo "=========================================="
    echo ""
    echo "Proverte:"
    echo "   1. Vy zaregistrirovany na https://signup.oraclecloud.com/"
    echo "   2. Ustanovlen OCI CLI: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm"
    echo "   3. Vypolnena komanda: oci setup config"
    echo ""
    read -rp "Compartment ID (iz Oracle Console): " COMPARTMENT_ID
    [ -z "$COMPARTMENT_ID" ] && err "Compartment ID obyazatelen"

    check_deps
    create_network
    create_instance
    deploy_app

    log "Gotovo! Vash sayt na Oracle Cloud Free Tier."
}

main "$@"
