#!/bin/bash

# Fungsi untuk memeriksa apakah pengguna adalah root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Script harus dijalankan sebagai root. Keluar..."
        exit 1
    fi
}

# Fungsi untuk menginstal lolcat jika belum terinstal
install_lolcat() {
    if ! command -v lolcat &> /dev/null; then
        echo "lolcat tidak ditemukan, menginstal lolcat..."
        sudo apt update -y &> /dev/null
        sudo apt install lolcat -y &> /dev/null
    fi
}

# Fungsi untuk menampilkan banner berwarna-warni
show_banner() {
    echo -e "\e[35m
         ______ ______  ___  
        |___  /|___  / / _ \ 
           / /    / / / /_\ \
          / /    / /  |  _  |
        ./ /___./ /___| | | |
        \_____/\_____/\_| |_/
                             
        ZEROTIER ZTNET AUTO INSTALL
            Powered by ZTNET
            Script by Mostech
    \e[0m" | lolcat
}

# Fungsi untuk menampilkan informasi sistem
show_system_info() {
    echo -e "\e[34mInformasi Sistem:\e[0m" | lolcat
    uname -a | lolcat
    
    echo -e "\e[34mInformasi OS:\e[0m" | lolcat
    lsb_release -a 2>/dev/null | lolcat
    
    echo -e "\e[34mInformasi CPU:\e[0m" | lolcat
    lscpu | grep 'Model name\|Architecture\|CPU(s)' | column -t | lolcat
    
    echo -e "\e[34mInformasi Memori:\e[0m" | lolcat
    free -h | column -t | lolcat
    
    echo -e "\e[34mInformasi Disk:\e[0m" | lolcat
    df -h | column -t | lolcat
}

# Fungsi untuk menampilkan animasi loading
show_loading() {
    echo -e "\e[33mProses sedang berjalan, harap tunggu...\e[0m" | lolcat
    while true; do
        for s in / - \\ \|; do
            printf "\r$s"
            sleep 0.1
        done
    done
}

# Fungsi untuk menghentikan animasi loading
stop_loading() {
    kill "$1"
    printf "\r"
}

# Bagian A
check_root
install_lolcat

echo "Menghapus needrestart..." | lolcat
show_loading &
LOADING_PID=$!
sudo apt -y remove needrestart &> /dev/null
stop_loading $LOADING_PID

echo "Mengubah konfigurasi needrestart..." | lolcat
show_loading &
LOADING_PID=$!
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf &> /dev/null
stop_loading $LOADING_PID

echo "Menginstal lolcat..." | lolcat
show_loading &
LOADING_PID=$!
sudo apt install lolcat -y &> /dev/null
stop_loading $LOADING_PID

show_banner

show_system_info

echo "Script akan dijalankan..." | lolcat

# Mengecek apakah Docker sudah diinstal
if ! command -v docker &> /dev/null; then

    # Bagian B
    echo "Docker tidak ditemukan, menginstal Docker..." | lolcat

    echo "Menginstal dependensi Docker..." | lolcat
    show_loading &
    LOADING_PID=$!
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y &> /dev/null
    stop_loading $LOADING_PID

    echo "Mengunduh kunci GPG Docker..." | lolcat
    show_loading &
    LOADING_PID=$!
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &> /dev/null
    stop_loading $LOADING_PID

    echo "Menambahkan repository Docker ke sources list..." | lolcat
    show_loading &
    LOADING_PID=$!
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    stop_loading $LOADING_PID

    echo "Memperbarui repository..." | lolcat
    show_loading &
    LOADING_PID=$!
    sudo apt update -y &> /dev/null
    stop_loading $LOADING_PID

    echo "Meng-upgrade sistem..." | lolcat
    show_loading &
    LOADING_PID=$!
    sudo apt upgrade -y &> /dev/null
    stop_loading $LOADING_PID

    echo "Menginstal Docker..." | lolcat
    show_loading &
    LOADING_PID=$!
    sudo apt install docker-ce -y &> /dev/null
    stop_loading $LOADING_PID

    echo "Menambahkan pengguna ke grup Docker..." | lolcat
    show_loading &
    LOADING_PID=$!
    sudo usermod -aG docker ${USER} &> /dev/null
    stop_loading $LOADING_PID

    echo "Docker berhasil diinstal." | lolcat
else
    echo "Docker sudah terinstal, melewatkan Bagian B..." | lolcat
fi

# Bagian C
echo "Memperbarui repository..." | lolcat
show_loading &
LOADING_PID=$!
sudo apt update -y &> /dev/null
stop_loading $LOADING_PID

echo "Meng-upgrade sistem..." | lolcat
show_loading &
LOADING_PID=$!
sudo apt upgrade -y &> /dev/null
stop_loading $LOADING_PID

echo -n "Masukkan nama domain yang akan digunakan di file docker-compose.yml: " | lolcat
read domain_name

echo "Membuat file docker-compose.yml..." | lolcat
show_loading &
LOADING_PID=$!
cat <<EOF > docker-compose.yml
services:
  postgres:
    image: postgres:15.2-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ztnet
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

  zerotier:
    image: zyclonite/zerotier:1.14.0
    hostname: zerotier
    container_name: zerotier
    restart: unless-stopped
    volumes:
      - zerotier:/var/lib/zerotier-one
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    networks:
      - app-network
    ports:
      - "9993:9993/udp"
    environment:
      - ZT_OVERRIDE_LOCAL_CONF=true
      - ZT_ALLOW_MANAGEMENT_FROM=172.31.255.0/29

  ztnet:
    image: sinamics/ztnet:latest
    container_name: ztnet
    working_dir: /app
    volumes:
      - zerotier:/var/lib/zerotier-one
    restart: unless-stopped
    ports:
      - 3000:3000
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ztnet
      NEXTAUTH_URL: "http://$domain_name:3000"
      NEXTAUTH_SECRET: "random_secret"
      NEXTAUTH_URL_INTERNAL: "http://ztnet:3000"
    networks:
      - app-network
    links:
      - postgres
    depends_on:
      - postgres
      - zerotier

volumes:
  zerotier:
  postgres-data:

networks:
  app-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.31.255.0/29
EOF
stop_loading $LOADING_PID

echo "File docker-compose.yml berhasil dibuat." | lolcat

echo "Script selesai." | lolcat
