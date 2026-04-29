# 🗳️ Multi-Stack DevOps Infrastructure Automation
### End-to-End Deployment of a Distributed Voting Application on AWS

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)

---

## 📋 Project Overview

A **polyglot microservices voting application** deployed across a 3-tier AWS architecture using modern DevOps practices. Users cast votes on a web frontend, votes are queued in Redis, processed by a .NET worker, persisted in PostgreSQL, and displayed in real-time on a results dashboard.

### 🔄 Application Flow

```
👤 User → 🗳️ Vote App (Flask) → 📮 Redis → ⚙️ Worker (.NET) → 🐘 PostgreSQL → 📊 Result App (Node.js) → 👤 User
```

### 🧩 Microservices

| Service | Technology | Port | Instance | Purpose |
|---|---|---|---|---|
| 🗳️ **Vote** | Python / Flask | `5000` | A (public) | Frontend where users cast votes |
| 📊 **Result** | Node.js / Express | `3000` | A (public) | Real-time results dashboard |
| ⚙️ **Worker** | .NET C# | internal | B (private) | Processes votes from Redis → PostgreSQL |
| 📮 **Redis** | Redis | `6379` | B (private) | In-memory message queue |
| 🐘 **PostgreSQL** | PostgreSQL 16 | `5432` | C (private) | Persistent vote storage |

---

## 🏗️ AWS Architecture

```
╔══════════════════════════════════════════════════════════════════╗
║                        🌐  INTERNET                             ║
╚══════════════════════════════════════════════════════════════════╝
                              │
                    HTTP :5000 / :3000
                              │
╔══════════════════════════════════════════════════════════════════╗
║                   🔀  INTERNET GATEWAY                          ║
╚══════════════════════════════════════════════════════════════════╝
                              │
╔══════════════════════════════════════════════════════════════════╗
║  🟢  PUBLIC SUBNET  (10.0.1.0/24)                               ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  📦 Instance A — instance-a-frontend-nata  (t3.micro)    │   ║
║  │     🗳️  Vote App       → port 5000                       │   ║
║  │     📊  Result App     → port 3000                       │   ║
║  │     🔑  Bastion Host   → SSH jump server                 │   ║
║  │     🛡️  vote-result-sg-nata                              │   ║
║  └──────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════╝
          │  Redis :6379 (from vote-result-sg)
          │  SSH ProxyJump (through Instance A)
╔══════════════════════════════════════════════════════════════════╗
║  🔴  PRIVATE SUBNET  (10.0.2.0/24)                              ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  📦 Instance B — instance-b-backend-nata  (t3.micro)     │   ║
║  │     📮  Redis          → port 6379  [voting-network]     │   ║
║  │     ⚙️   Worker (.NET) → reads Redis, writes Postgres     │   ║
║  │     🛡️  redis-worker-sg-nata                             │   ║
║  └──────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════╝
          │  PostgreSQL :5432 (from redis-worker-sg)
╔══════════════════════════════════════════════════════════════════╗
║  🔴  PRIVATE SUBNET  (10.0.2.0/24)                              ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  📦 Instance C — instance-c-database-nata  (t3.micro)    │   ║
║  │     🐘  PostgreSQL 16  → port 5432                       │   ║
║  │     💾  Volume         → postgres_data (persistent)      │   ║
║  │     🛡️  postgres-sg-nata                                 │   ║
║  └──────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════╝
          ↑
    🔁 NAT Gateway + Elastic IP
    (outbound internet for private instances — Docker pulls, packages)
```

---

## 📁 Project Structure

```
ironhack-project-1/
├── 📄 LICENSE
├── 📄 README.md
│
├── 📂 ansible/                          # Part 3 — Configuration Management
│   ├── ansible.cfg                      # SSH settings (key path, host key checking)
│   ├── inventory.ini                    # EC2 instances + ProxyCommand for private access
│   └── playbook.yml                     # 4-play deployment automation
│
├── 📂 terraform/                        # Part 2 — Infrastructure as Code
│   ├── main.tf                          # 16 AWS resources (VPC, EC2, SGs, NAT, IGW...)
│   ├── providers.tf                     # hashicorp/aws ~>5.40.0 + S3 remote backend
│   └── output.tf                        # Outputs: public IP (A), private IPs (B, C)
│
├── 📂 vote/                             # Part 1 — Microservice 1 — Python/Flask
│   ├── Dockerfile                       # gunicorn production server
│   ├── app.py                           # Flask app — receives votes, pushes to Redis
│   ├── requirements.txt                 # Flask, Redis, gunicorn
│   ├── static/stylesheets/style.css
│   └── templates/index.html
│
├── 📂 result/                           # Part 1 — Microservice 2 — Node.js
│   ├── Dockerfile                       # nodemon → port 80
│   ├── server.js                        # Express + Socket.io (reads PostgreSQL, live updates)
│   ├── package.json
│   ├── package-lock.json
│   └── views/
│       ├── index.html                   # Angular frontend
│       ├── app.js
│       ├── socket.io.js
│       ├── angular.min.js
│       └── stylesheets/style.css
│
├── 📂 worker/                           # Part 1 — Microservice 3 — .NET C#
│   ├── Dockerfile                       # Multi-stage build: SDK → runtime
│   ├── Program.cs                       # Reads Redis queue, writes to PostgreSQL
│   └── Worker.csproj                    # .NET 8.0 project file
│
├── 📂 healthchecks/                     # Service connectivity scripts
│   ├── postgres.sh                      # Tests PostgreSQL :5432
│   └── redis.sh                         # Tests Redis :6379
│
├── 🐳 docker-compose.yml               # Part 1 — Local dev orchestration (all 5 services)
└── 🔒 .gitignore                        # Excludes .terraform/, *.tfstate, obj/, .DS_Store
```

---

## 🐳 Part 1 — Docker Containerization

### DockerHub Images
```
natavan91/voting-app:latest    # Python/Flask vote frontend
natavan91/result-app:latest    # Node.js results dashboard
natavan91/worker-app:latest    # .NET C# vote processor
```

### ⚠️ ARM vs AMD64 — Key Challenge
Images built on **Apple Silicon (M1/M2)** use ARM architecture — **incompatible** with AWS EC2 AMD64 instances. Error: `no matching manifest for linux/amd64`.

**Solution:** Build images directly on EC2 (natively AMD64):
```bash
ssh frontend-instance-1
git clone https://github.com/natavann/ironhack-project-1.git
cd ironhack-project-1

cd vote    && docker build -t natavan91/voting-app:latest . && docker push natavan91/voting-app:latest
cd ../result && docker build -t natavan91/result-app:latest . && docker push natavan91/result-app:latest
cd ../worker && docker build -t natavan91/worker-app:latest . && docker push natavan91/worker-app:latest
```

---

## ☁️ Part 2 — Terraform Infrastructure

### providers.tf
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }
  backend "s3" {
    bucket         = "voting-project-bucket-nata"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "voting-project-state-lock-nata"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### ⚠️ Manual Prerequisites (One-Time Setup)
> Terraform needs a remote backend before it can run — chicken-and-egg problem. Create these manually in AWS Console first:

1. **S3 Bucket** → `voting-project-bucket-nata` (enable versioning)
2. **DynamoDB Table** → `voting-project-state-lock-nata` with partition key `LockID` (String)

### AWS Resources (main.tf — 16 total)

| # | Resource | Name Tag | Configuration |
|---|---|---|---|
| 1 | `aws_vpc` | `voting-app-vpc-nata` | 10.0.0.0/16, DNS enabled |
| 2 | `aws_subnet` public | `public-subnet-nata` | 10.0.1.0/24, us-east-1a, auto-assign IP |
| 3 | `aws_subnet` private | `private-subnet-nata` | 10.0.2.0/24, us-east-1a |
| 4 | `aws_internet_gateway` | `voting-app-igw-nata` | Attached to VPC |
| 5 | `aws_route_table` public | `public-rt-nata` | 0.0.0.0/0 → IGW |
| 6 | `aws_route_table_association` public | — | Public subnet → public RT |
| 7 | `aws_security_group` A | `vote-result-sg-nata` | 80, 443, 5000, 3000, 22 from 0.0.0.0/0 |
| 8 | `aws_security_group` B | `redis-worker-sg-nata` | 6379 + 22 from vote-result-sg only |
| 9 | `aws_security_group` C | `postgres-sg-nata` | 5432 from redis-worker-sg + vote-result-sg, 22 from vote-result-sg |
| 10 | `aws_instance` A | `instance-a-frontend-nata` | t3.micro, public subnet, vote-result-sg |
| 11 | `aws_instance` B | `instance-b-backend-nata` | t3.micro, private subnet, redis-worker-sg |
| 12 | `aws_instance` C | `instance-c-database-nata` | t3.micro, private subnet, postgres-sg |
| 13 | `aws_eip` | `nat-eip-nata` | Static IP for NAT Gateway |
| 14 | `aws_nat_gateway` | `voting-app-nat-nata` | Public subnet, depends_on IGW |
| 15 | `aws_route_table` private | `private-rt-nata` | 0.0.0.0/0 → NAT Gateway |
| 16 | `aws_route_table_association` private | — | Private subnet → private RT |

### Security Group Chaining
```
🌐 Internet
      │  ports: 80, 443, 5000, 3000, 22
      ▼
🛡️  vote-result-sg-nata    (Instance A — public)
      │  allows inbound: 80, 443, 5000, 3000, 22 from 0.0.0.0/0
      │
      │  port 6379 → to redis-worker-sg (Instance B)
      │  port 5432 → to postgres-sg (Instance C)
      ▼
🛡️  redis-worker-sg-nata   (Instance B — private)
      │  port 6379 — source: vote-result-sg only
      │  port 22   — source: vote-result-sg only
      ▼
🛡️  postgres-sg-nata       (Instance C — private)
      │  port 5432 — source: redis-worker-sg + vote-result-sg
      │  port 22   — source: vote-result-sg only
```

### Terraform Commands
```bash
cd terraform

terraform init      # Download provider + connect to S3 backend
terraform plan      # Preview all resources (dry run)
terraform apply     # Create all 16 resources on AWS
terraform output    # Show instance IP addresses
terraform destroy   # Tear down all resources
```
---

## 🤖 Part 3 — Ansible Configuration & Deployment

### SSH Config (~/.ssh/config)
```
Host frontend-instance-1
    HostName <INSTANCE_A_PUBLIC_IP>
    User ec2-user
    IdentityFile ~/.ssh/key_name.pem

Host backend-instance-1
    HostName <INSTANCE_B_PRIVATE_IP>
    User ec2-user
    ProxyJump frontend-instance-1
    IdentityFile ~/.ssh/key_name.pem

Host db-instance-1
    HostName <INSTANCE_C_PRIVATE_IP>
    User ec2-user
    ProxyJump frontend-instance-1
    IdentityFile ~/.ssh/key_name.pem
```

### Inventory (inventory.ini)
```ini
[frontend]
frontend-instance-1 ansible_host=<INSTANCE_A_PUBLIC_IP>

[backend]
backend-instance-1 ansible_host=<INSTANCE_B_PRIVATE_IP>

[db]
db-instance-1 ansible_host=<INSTANCE_C_PRIVATE_IP>

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=/path/to/key_name.pem
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i /path/to/key_name.pem ec2-user@<INSTANCE_A_PUBLIC_IP>"'
```

### Playbook (playbook.yml) — 4 Plays

**▶ Play 1 — Install Docker (hosts: all)**
```
- Update package index (yum)
- Install docker package
- Start and enable docker service
- Add ec2-user to docker group
```

**▶ Play 2 — Deploy Frontend (hosts: frontend → Instance A)**
```
- Pull natavan91/voting-app → run on port 5000:80
  env: REDIS_HOST = {{ hostvars['backend-instance-1']['ansible_host'] }}

- Pull natavan91/result-app → run on port 3000:80
  env: PG_HOST     = {{ hostvars['db-instance-1']['ansible_host'] }}
       PG_DATABASE = votes
```

**▶ Play 3 — Deploy Backend (hosts: backend → Instance B)**
```
- Create docker network: voting-network
- Pull redis:latest → run on port 6379 (voting-network)
- Pull natavan91/worker-app → run on voting-network
  env: REDIS_HOST  = redis   ← container name DNS (same network)
       DB_HOST     = {{ hostvars['db-instance-1']['ansible_host'] }}
       DB_NAME     = votes
       DB_USERNAME = postgres
       DB_PASSWORD = postgres
```

**▶ Play 4 — Deploy Database (hosts: db → Instance C)**
```
- Pull postgres:16 → run on port 5432
  env: POSTGRES_USER     = postgres
       POSTGRES_PASSWORD = postgres
       POSTGRES_DB       = votes
```

### Ansible Commands
```bash
cd ansible

ansible all -i inventory.ini -m ping              # Test connectivity
ansible-playbook -i inventory.ini playbook.yml    # Full deployment
ansible-playbook -i inventory.ini playbook.yml -vvv  # Verbose debug
```

### 🌐 Accessing the Application on AWS
After running `ansible-playbook -i inventory.ini playbook.yml` the app is live on AWS:

| Service | URL |
|---|---|
| 🗳️ Vote App | `http://<INSTANCE_A_PUBLIC_IP>:5000` |
| 📊 Result App | `http://<INSTANCE_A_PUBLIC_IP>:3000` |

> Get the public IP with: `terraform output instance_a_public_ip`
---

## 🔧 Project Add-Ons

### ✅ Proper Security Group Configs
SGs use **SG-to-SG references** not open CIDR ranges — strict firewall chain between tiers. Backend only accepts from frontend SG. Database only accepts from backend SG.

### ✅ PostgreSQL Volume for Data Persistence
```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
```
> ⚠️ Use `postgres:16` not `postgres:latest`. PostgreSQL 18 (latest) changed its data directory format — incompatible with volumes from earlier versions.

### ✅ Remote State — S3 + DynamoDB
- State: `voting-project-bucket-nata` S3 bucket
- Locking: `voting-project-state-lock-nata` DynamoDB table
- Enables safe team collaboration on the same infrastructure

---

## 🐛 Key Challenges & Solutions

| Challenge | Root Cause | Solution |
|---|---|---|
| 🏗️ ARM vs AMD64 | Mac M1 builds ARM images | Built images directly on EC2 (AMD64) |
| 🐔 Terraform bootstrap | S3/DynamoDB needed before Terraform runs | Created both manually once |
| 🔒 Private instance access | No public IP on Instances B & C | Bastion Host + SSH ProxyJump through A |
| 🌐 Private internet access | Private instances need Docker pulls | NAT Gateway — outbound only |
| 🔌 OrbStack SSH issue | ProxyCommand intercepted on wrong port | Absolute file paths in inventory.ini |
| 🐳 Redis-Worker networking | Containers couldn't reach each other | Shared `voting-network` on Instance B |
| 📍 Dynamic private IPs | IPs change on EC2 restart | Ansible `hostvars` dynamically injects IPs |

---

## 📊 Results

| Metric | Value |
|---|---|
| ☁️ AWS Resources Provisioned | **16** |
| 🖥️ EC2 Instances Deployed | **3** |
| 🐳 Microservices Containerized | **5** |
| 📝 Infrastructure as Code | **100%** |
| 🛡️ Security Groups | **3** |
| 🔒 Private Instances (no public IP) | **2** |

---

## 🛠️ Tools & Technologies

| Tool | Version | Purpose |
|---|---|---|
| 🐳 Docker | Latest | Container runtime |
| 🐙 Docker Compose | Latest | Local orchestration |
| 🏗️ Terraform | v1.7+ / AWS provider ~>5.40.0 | Infrastructure as Code |
| 🤖 Ansible | v2.19 | Configuration management |
| ☁️ AWS EC2 | t3.micro, Amazon Linux 2023 | Virtual machines |
| 🌐 AWS VPC | 10.0.0.0/16 | Network isolation |
| 🪣 AWS S3 | voting-project-bucket-nata | Terraform remote state |
| 🔒 AWS DynamoDB | voting-project-state-lock-nata | State locking |
| 🔀 AWS NAT Gateway | With Elastic IP | Private subnet internet access |

---

## 💥 Teardown

```bash
cd terraform
terraform destroy
```

> ⚠️ The S3 bucket and DynamoDB table are **not destroyed** by `terraform destroy` — they must be deleted manually in the AWS Console if a full teardown is required.

> 💾 Back up PostgreSQL data before destroying:
> ```bash
> ssh db-instance-1 "docker exec postgres pg_dump -U postgres votes" > ~/Desktop/votes_backup.sql
> ```

---

## 👤 Author

**Natavan** — DevOps Infrastructure Project 2026

[![GitHub](https://img.shields.io/badge/GitHub-natavann-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/natavann)
