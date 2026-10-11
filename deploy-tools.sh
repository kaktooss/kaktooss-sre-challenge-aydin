sudo apt update
#java
sudo apt install openjdk-21-jdk
# mkcert to create ssl local certificates
sudo apt install wget libnss3-tools -y
# Create Certs
cd certs
mkcert -install
mkcert demo-front.local
mkcert demo-reader.local

