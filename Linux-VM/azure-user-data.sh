#! /bin/bash
sudo apt-get update -y
sudo apt-get install nmap -y
sudo apt install docker.io -y
sudo snap install docker -y
docker pull rustscan/rustscan:1.10.0