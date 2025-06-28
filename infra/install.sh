#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io docker-compose awscli jq

sudo systemctl enable docker
sudo usermod -aG docker ubuntu
