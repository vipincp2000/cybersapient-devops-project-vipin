Cybersapient DevOps Project – Fullstack Deployment on AWS
---------------------------------------------------------

This project demonstrates deploying a fullstack application (React + Node.js) using Docker, Terraform for AWS infrastructure, and GitHub Actions for CI/CD.

Tech Stack-

Frontend: React (served via Nginx)

Backend: Node.js (Express)

Containerization: Docker, Docker Compose

Infrastructure as Code: Terraform

Cloud: AWS (EC2, RDS, S3, Secrets Manager)

CI/CD: GitHub Actions

Monitoring: Prometheus + Grafana

 Project Structure
.
├── docker-compose.yml
├── frontend/
├── backend/
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── userdata.sh
├── .github/
│   └── workflows/
│       └── deploy.yml
└── README.md

Deployment Overview
1. Infrastructure Setup (via Terraform)
Provisioned on AWS:

a) VPC with public subnet

b) EC2 (Ubuntu) with Docker + Docker Compose

c) RDS PostgreSQL

d) S3 bucket for asset storage

e) IAM roles for Secrets Manager access

f) Secrets stored in AWS Secrets Manager

Setting Up Infrastructure

cd infra
terraform init
terraform apply
This will provision EC2, RDS, VPC, and S3, and inject secrets into Secrets Manager.

CI/CD Setup (GitHub Actions):-
-----------------------------

Trigger: On push/merge to main
Steps performed:

SSH into EC2

Clone or update the app repo

Run docker-compose up -d --build

Required GitHub Secrets

Add the following to your GitHub repo:

Secret Name	Description
EC2_HOST	EC2 public IP
EC2_USER	ubuntu
EC2_SSH_KEY	Base64-encoded private .pem key
