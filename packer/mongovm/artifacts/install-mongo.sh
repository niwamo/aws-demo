export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
sudo apt update
sudo apt install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-4.4.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.4 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable mongod