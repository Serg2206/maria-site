# Oracle Cloud Deploy — MARIA-site

## Chto eto
Avtomaticheskoye razvertyvaniye sayta Medical Center MARIA na **Oracle Cloud Free Tier**.

## Chto poluchite (Always Free — navsegda besplatno)
- **4 ARM yadra** (Ampere A1)
- **24 GB RAM**
- **200 GB SSD**
- **10 TB trafika/mesyats**
- Ubuntu 22.04 LTS

## Shag 1: Registratsiya na Oracle Cloud (delayete vruchnuyu)
1. Otkryvayem: https://signup.oraclecloud.com/
2. Vvodim email → podtverzhdayem
3. Vvodim imya, telefon, stranu (Ukraine)
4. **Vvodim kartu** (Visa/Mastercard) — dengi NE snimayutsya, tolko proverka $1
5. Posle podtverzhdeniya — vkhodim v konsol: https://cloud.oracle.com/

## Shag 2: Ustanovka OCI CLI (na vash kompyuter)
```bash
curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash
exec -l $SHELL
oci setup config
# Sleduyem instruktsiyam — vstavlyaem API klyuch iz Oracle Console
```

## Shag 3: Nayti Compartment ID
1. Oracle Console → Profile (verkhniy pravyy ugol) → Tenancy
2. Kopiruyem **OCID** (nachinayetsya s `ocid1.tenancy.oc1...`)

## Shag 4: Zapusk deploya (varianty)

### Variant A: Bash skript (prosche)
```bash
export COMPARTMENT_ID="ocid1.tenancy.oc1..."
./oracle-cloud-deploy.sh
```

### Variant B: Terraform (nadezhnee)
```bash
cd deploy/
terraform init
terraform plan -var="compartment_id=ocid1.tenancy.oc1..."
terraform apply -var="compartment_id=ocid1.tenancy.oc1..."
# Poluchaem IP i SSH-komandu na vykhode
```

## Shag 5: DuckDNS (besplatnyy domen)
1. Registriruemsya: https://www.duckdns.org/
2. Sozdayem poddomen: `maria-site`
3. Vstavlyaem IP servera (iz vyvoda terraform)
4. Sokhranyaem

## Shag 6: SSL (Let\'s Encrypt)
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<IP>
sudo apt install certbot
sudo certbot --standalone -d maria-site.duckdns.org
```

## Posle deploya
- Sayt: `https://maria-site.duckdns.org`
- SSH: `ssh -i ~/.ssh/id_rsa ubuntu@<IP>`
- Logi: `ssh ... "docker logs nginx"`
