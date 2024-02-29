#!/bin/bash
# Update apt repo
sudo apt update 
# Install Docker
sudo apt install docker.io -y
# Install azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Install AKS CLI (kubectl)
sudo az aks install-cli
