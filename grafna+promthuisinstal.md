A. Prometheus installeren

Voer dit uit op je Grafana/Prometheus-container:

apt update
apt upgrade -y

apt install prometheus prometheus-node-exporter prometheus-node-exporter-collectors -y

systemctl enable --now prometheus
systemctl enable --now prometheus-node-exporter

systemctl status prometheus
systemctl status prometheus-node-exporter

Controleer:

ss -tulpn | grep -E '9090|9100'

Je zou poorten 9090 en 9100 moeten zien.

B. Prometheus configureren

Maak eerst een backup van de configuratie:

cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.backup

Open het bestand:

nano /etc/prometheus/prometheus.yml

Verwijder alles en plak dit:

global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "localhost:9093"

rule_files:

scrape_configs:

  - job_name: "prometheus"
    scrape_interval: 5s
    static_configs:
      - targets:
          - "localhost:9090"

  - job_name: "node"
    static_configs:
      - targets:
          - "localhost:9100"

  - job_name: "linux_servers"
    static_configs:
      - targets:
          - "10.24.20.2:9100"
          - "10.24.20.3:9100"
          - "10.24.20.4:9100"

Opslaan:

CTRL + O
Enter
CTRL + X
C. Configuratie controleren
promtool check config /etc/prometheus/prometheus.yml

Je wilt:

SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax

Daarna:

systemctl restart prometheus

Controleer:

systemctl status prometheus
D. Node Exporter installeren op de andere servers

Dit moet je uitvoeren op 10.24.20.2, 10.24.20.3 en 10.24.20.4.

Op iedere server:

apt update
apt install prometheus-node-exporter -y

Start Node Exporter:

systemctl enable --now prometheus-node-exporter

Controleer:

systemctl status prometheus-node-exporter

Controleer poort:

ss -tulpn | grep 9100

Test lokaal:

curl http://localhost:9100/metrics

Je moet een hele lijst met metrics krijgen, bijvoorbeeld:

# HELP node_cpu_seconds_total ...
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total ...
E. Verbinding testen vanaf Prometheus

Ga terug naar je Grafana/Prometheus-container.

Test:

curl http://10.24.20.2:9100/metrics

Daarna:

curl http://10.24.20.3:9100/metrics

En:

curl http://10.24.20.4:9100/metrics

Als alle drie een grote hoeveelheid metrics teruggeven, kan Prometheus de servers bereiken.

F. Prometheus controleren

Open op je pc:

http://IP-VAN-JE-GRAFANA-CONTAINER:9090

Ga vervolgens naar:

Status → Targets

Je zou ongeveer dit moeten zien:

prometheus
localhost:9090
UP

node
localhost:9100
UP

linux_servers
10.24.20.2:9100
UP

10.24.20.3:9100
UP

10.24.20.4:9100
UP

Als een server DOWN staat, controleer dan eerst:

curl http://IP:9100/metrics
G. Grafana installeren

Op dezelfde Grafana-container:

apt install -y apt-transport-https wget gpg
mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt update

Installeer:

apt install grafana -y

Start Grafana:

systemctl enable --now grafana-server

Controleer:

systemctl status grafana-server
H. Grafana openen

Als je Grafana-container bijvoorbeeld:

10.24.20.10

heeft, ga je op je Windows-pc naar:

http://10.24.20.10:3000

Grafana gebruikt standaard:

poort 3000

Prometheus gebruikt:

poort 9090

Node Exporter gebruikt:

poort 9100
I. Prometheus koppelen aan Grafana

In Grafana:

Connections → Data sources → Add new data source → Prometheus

Bij Prometheus server URL:

http://localhost:9090

Omdat Prometheus en Grafana op dezelfde container staan.

Klik:

Save & test

Je wilt een succesvolle verbinding krijgen.

J. Dashboard maken

Daarna kun je een bestaand Node Exporter dashboard importeren.

In Grafana:

Dashboards → New → Import

Je kunt vervolgens een Node Exporter dashboard importeren.

Daarmee kun je onder andere bekijken:

CPU usage
RAM usage
Disk usage
Network traffic
Disk I/O
Load
Uptime

De volledige datastroom is dan:

              ┌────────────────────────┐
              │ Grafana/Prometheus LXC │
              │                        │
              │ Prometheus :9090       │
              │ Grafana    :3000       │
              │ Node Exporter :9100    │
              └───────────┬────────────┘
                          │
                    scrape metrics
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
   10.24.20.2       10.24.20.3       10.24.20.4
      :9100            :9100            :9100
          │               │               │
          ▼               ▼               ▼
       Node             Node             Node
      Exporter         Exporter         Exporter

Bewaar vooral ook dit bestand /etc/prometheus/prometheus.yml.backup. Als je later je configuratie verpest, kun je terug naar de werkende versie met:

cp /etc/prometheus/prometheus.yml.backup /etc/prometheus/prometheus.yml
systemctl restart prometheus