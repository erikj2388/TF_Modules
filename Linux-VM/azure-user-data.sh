#! /bin/bash
sudo apt-get update -y
sudo apt install docker.io -y
sudo snap install docker -y
docker pull rustscan/rustscan:2.0.1