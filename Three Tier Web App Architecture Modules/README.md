# 🚀 Enterprise 3-Tier Application Infrastructure (Terraform)

An enterprise-grade, highly available, and secure **3-Tier Web Application** infrastructure provisioned entirely as code using **Terraform**. This project follows modular infrastructure design patterns and AWS best practices for robust production environments.

---

## 🏗️ Architecture Overview

The infrastructure is deployed across multiple Availability Zones (AZs) in AWS (`us-east-1`) to ensure high availability, fault tolerance, and security isolation:

1. **Presentation Tier (Public Subnets):**
   * Internet Gateway (`igw`) & Public Route Tables.
   * NAT Gateways with dedicated Elastic IPs for secure outbound internet routing from private tiers.
   * Application Load Balancer (ALB) entry points.
2. **Application Tier (Private App Subnets):**
   * Scalable EC2 Application Servers running behind the load balancer.
   * Security groups strictly restricting inbound traffic on port `8080` exclusively from the ALB security group.
   * IAM Roles and Instance Profiles configured with CloudWatch logging permissions.
3. **Database Tier (Private DB Subnets):**
   * Highly isolated database subnets.
   * Security groups permitting MySQL/PostgreSQL traffic (`3306`) exclusively from the Application security group.
4. **Storage Tier:**
   * Secured S3 Bucket for application media assets with public access completely blocked, server-side encryption enabled (`AES256`), and versioning active.

---

## 📂 Project Directory Structure

```text
.
├── main.tf                 # Root module orchestrating all child modules
├── variables.tf            # Root input variables
├── outputs.tf              # Root output definitions
├── providers.tf            # Provider configurations (AWS & version constraints)
└── modules/
    ├── vpc/                # Networking (VPCs, Subnets, IGW, NAT, Route Tables)
    ├── security/           # IAM Roles, Instance Profiles, and Security Groups
    ├── storage/            # Encrypted and secured S3 Buckets
    ├── compute/            # EC2 Application Servers
    └── database/           # Isolated RDS MySQL Database tier

  🛠️ Prerequisites
Terraform >= 1.5.0 installed on your machine.

AWS CLI (Optional for live deployments).

⚙️ Local Testing & Validation
This project supports mock configurations to allow local syntax validation and plan testing without requiring live AWS credentials or incurring cloud costs:

 skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_key"
  secret_key                  = "mock_key"
  
Clone or open the repository in VS Code.

Initialize Terraform:
terraform init

Run the execution plan:
terraform plan

🚀 Deployment Guide (Production)
To provision this architecture in a real AWS account:

Configure your valid AWS credentials:
export AWS_ACCESS_KEY_ID="your_real_access_key"
export AWS_SECRET_ACCESS_KEY="your_real_secret_key"

Update providers.tf to remove mock override flags (such as skip_credentials_validation if deploying live).

Apply the configuration:
terraform apply

Security Best Practices
Principle of Least Privilege: Security groups tightly interlock each tier (ALB ➔ App ➔ DB).

Storage Encryption: S3 buckets force AES256 encryption and block public ACLs/policies.

Network Segregation: Backend and database resources reside entirely inside private subnets away from direct exposure.

## 👩‍💻 Author

**Will Farid**

Cloud Engineer

---

## ⭐ Support

If you found this project useful, consider giving it a ⭐ on GitHub.