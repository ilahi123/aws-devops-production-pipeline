# 🚀 AWS CI/CD Pipeline — End-to-End Containerized Deployment

[![Deploy to Amazon ECS](https://img.shields.io/badge/Deploy-Amazon%20ECS-FF9900?style=for-the-badge&logo=amazon-ecs&logoColor=white)](https://aws.amazon.com/ecs/)
[![CloudFormation](https://img.shields.io/badge/IaC-CloudFormation-FF4F8B?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/cloudformation/)
[![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/Runtime-Node.js%2020-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)

> **A production-grade CI/CD pipeline** that automates building, testing, and deploying a containerized Node.js application to **AWS ECS Fargate** using **GitHub Actions**, **Amazon ECR**, **Application Load Balancer**, and **AWS CloudFormation** — all provisioned as Infrastructure as Code (IaC).

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture Diagram](#-architecture-diagram)
- [AWS Services Used](#-aws-services-used)
- [Project Structure](#-project-structure)
- [Infrastructure Deep Dive](#-infrastructure-deep-dive)
  - [VPC & Networking](#1-vpc--networking)
  - [IAM Roles & Security](#2-iam-roles--security)
  - [Application Load Balancer (ALB)](#3-application-load-balancer-alb)
  - [ECS Fargate Cluster](#4-ecs-fargate-cluster)
  - [Amazon ECR](#5-amazon-ecr)
  - [CloudWatch Logging](#6-cloudwatch-logging)
- [CI/CD Pipeline Workflow](#-cicd-pipeline-workflow)
- [Blue/Green Deployment Strategy](#-bluegreen-deployment-strategy)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Local Development](#local-development)
  - [Deploy to AWS](#deploy-to-aws)
  - [Tear Down](#tear-down)
- [Environment Variables](#-environment-variables)
- [API Endpoints](#-api-endpoints)
- [Testing](#-testing)
- [Security Best Practices](#-security-best-practices)
- [Cost Optimization](#-cost-optimization)
- [Troubleshooting](#-troubleshooting)
- [Future Enhancements](#-future-enhancements)

---

## 🌐 Project Overview

This project demonstrates a **complete DevOps workflow** for deploying a containerized microservice to AWS. It covers the full lifecycle:

| Phase | What Happens | AWS Services |
|:------|:-------------|:-------------|
| **Code** | Developer pushes to `main` branch | GitHub |
| **Test** | Automated unit tests run (Jest + Supertest) | GitHub Actions |
| **Build** | Docker image built via multi-stage build | Docker |
| **Push** | Image pushed to private registry | Amazon ECR |
| **Provision** | Infrastructure created/updated via IaC | AWS CloudFormation |
| **Deploy** | Containers deployed to serverless compute | ECS Fargate |
| **Route** | Traffic routed through load balancer | ALB |
| **Monitor** | Application logs streamed and retained | CloudWatch Logs |

### Key Highlights

- ✅ **Fully Automated** — Zero manual intervention from code push to production
- ✅ **Infrastructure as Code** — Every AWS resource defined in CloudFormation YAML
- ✅ **Serverless Containers** — No EC2 instances to manage (Fargate launch type)
- ✅ **Blue/Green Ready** — Two target groups provisioned for zero-downtime deployments
- ✅ **Multi-AZ** — Application runs across 2 Availability Zones for high availability
- ✅ **Secure by Design** — Least-privilege IAM, security group isolation, no SSH access
- ✅ **Multi-Stage Docker** — Optimized production image with minimal attack surface

---

## 🏗 Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              GITHUB ACTIONS CI/CD                               │
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐    ┌───────────────────────┐   │
│  │  Checkout │───▶│  Test    │───▶│ Docker Build  │───▶│ Push to Amazon ECR   │   │
│  │   Code   │    │ (Jest)   │    │ (Multi-Stage) │    │  (Tag: commit SHA)   │   │
│  └──────────┘    └──────────┘    └──────────────┘    └──────────┬────────────┘   │
│                                                                 │                │
│  ┌──────────────────────────────────────────────────────────────▼────────────┐   │
│  │              CloudFormation Deploy (aws-cloudformation-github-deploy)     │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           AWS CLOUD (ap-south-1)                                │
│                                                                                  │
│  ┌──────────────────────── VPC: 10.0.0.0/16 ────────────────────────────────┐   │
│  │                                                                           │   │
│  │   ┌─────────────────────────────────────────────────────────────────┐     │   │
│  │   │                    Internet Gateway (IGW)                       │     │   │
│  │   └─────────────────────────┬───────────────────────────────────────┘     │   │
│  │                             │                                             │   │
│  │                     ┌───────▼───────┐                                     │   │
│  │                     │  Public Route  │                                     │   │
│  │                     │    Table       │                                     │   │
│  │                     └───┬───────┬───┘                                     │   │
│  │                         │       │                                         │   │
│  │   ┌─────────────────────▼─┐   ┌─▼─────────────────────┐                  │   │
│  │   │  Public Subnet 1      │   │  Public Subnet 2      │                  │   │
│  │   │  10.0.1.0/24          │   │  10.0.2.0/24          │                  │   │
│  │   │  (AZ-1)               │   │  (AZ-2)               │                  │   │
│  │   └──────────┬────────────┘   └────────────┬──────────┘                  │   │
│  │              │                              │                             │   │
│  │   ┌──────────▼──────────────────────────────▼──────────┐                  │   │
│  │   │        Application Load Balancer (ALB)             │                  │   │
│  │   │            Port 80 (HTTP Listener)                 │                  │   │
│  │   └──────────┬──────────────────────────────┬──────────┘                  │   │
│  │              │                              │                             │   │
│  │   ┌──────────▼──────────┐   ┌───────────────▼──────────┐                  │   │
│  │   │  Target Group BLUE  │   │  Target Group GREEN      │                  │   │
│  │   │  (Active Traffic)   │   │  (Standby / Next Deploy) │                  │   │
│  │   └──────────┬──────────┘   └──────────────────────────┘                  │   │
│  │              │                                                            │   │
│  │   ┌──────────▼─────────────────────────────────────────┐                  │   │
│  │   │              ECS Cluster (Fargate)                  │                  │   │
│  │   │  ┌──────────────────┐  ┌──────────────────┐        │                  │   │
│  │   │  │  Task (Fargate)  │  │  Task (Fargate)  │        │                  │   │
│  │   │  │  ┌────────────┐  │  │  ┌────────────┐  │        │                  │   │
│  │   │  │  │ app-container│  │  │ │ app-container│  │        │                  │   │
│  │   │  │  │ (Node.js)  │  │  │  │ (Node.js)  │  │        │                  │   │
│  │   │  │  └────────────┘  │  │  └────────────┘  │        │                  │   │
│  │   │  │  CPU: 0.25 vCPU  │  │  CPU: 0.25 vCPU  │        │                  │   │
│  │   │  │  Mem: 512 MB     │  │  Mem: 512 MB     │        │                  │   │
│  │   │  └──────────────────┘  └──────────────────┘        │                  │   │
│  │   └────────────────────────────────────────────────────┘                  │   │
│  │                                                                           │   │
│  └───────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌─────────────────────────┐    ┌──────────────────────────────────────────┐     │
│  │   Amazon ECR            │    │   CloudWatch Logs                        │     │
│  │   (Container Registry)  │    │   /ecs/ci-cd-pipeline-app               │     │
│  │   ci-cd-pipeline-repo   │    │   Retention: 14 days                    │     │
│  └─────────────────────────┘    └──────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## ☁️ AWS Services Used

| Service | Purpose | Why This Service? |
|:--------|:--------|:------------------|
| **Amazon VPC** | Isolated virtual network with custom CIDR, subnets, route tables, and IGW | Provides network-level isolation and full control over IP addressing, routing, and security boundaries |
| **Amazon ECS (Fargate)** | Serverless container orchestration | Eliminates EC2 management overhead; auto-scales tasks; integrates natively with ALB, ECR, and CloudWatch |
| **Amazon ECR** | Private Docker container registry | Fully managed, encrypted-at-rest, integrated with IAM for fine-grained pull/push access control |
| **Elastic Load Balancing (ALB)** | Layer 7 HTTP load balancer with target group routing | Enables health checks, path-based routing, and blue/green deployments via dual target groups |
| **AWS CloudFormation** | Infrastructure as Code (IaC) engine | Declarative YAML templates for reproducible, version-controlled infrastructure; supports stack rollback |
| **AWS IAM** | Identity and access management | Least-privilege roles for ECS task execution and runtime; scoped to only required API actions |
| **Amazon CloudWatch Logs** | Centralized log management | Native integration with ECS via `awslogs` driver; supports retention policies, metric filters, and alarms |
| **GitHub Actions** | CI/CD orchestration | Event-driven workflows with native AWS action integrations; free for public repos |

---

## 📁 Project Structure

```
aws-devops-production-pipeline/
│
├── 📂 .github/
│   └── 📂 workflows/
│       └── 📄 deploy.yml              # GitHub Actions CI/CD pipeline definition
│
├── 📂 app/
│   ├── 📄 Dockerfile                  # Multi-stage Docker build (builder + production)
│   ├── 📄 package.json                # Node.js dependencies & scripts
│   ├── 📄 package-lock.json           # Locked dependency tree
│   └── 📂 src/
│       ├── 📄 index.js                # Express.js API server (health check + root endpoint)
│       └── 📄 index.test.js           # Jest + Supertest unit tests
│
├── 📂 cloudformation/
│   └── 📄 main.yml                    # Unified CloudFormation stack (VPC, IAM, ALB, ECS)
│
├── 📂 scripts/
│   ├── 📄 deploy.sh                   # Manual deployment script (CloudFormation deploy)
│   └── 📄 destroy.sh                  # Teardown script (CloudFormation delete-stack)
│
├── 📂 .aws/
│   └── 📄 task-definition.json        # ECS task definition (used by CI/CD)
│
├── 📄 .env                            # Environment variables (⚠️ not committed)
└── 📄 .gitignore                      # Ignored files & directories
```

---

## 🔬 Infrastructure Deep Dive

The entire infrastructure is defined in a single CloudFormation template ([`cloudformation/main.yml`](cloudformation/main.yml)) containing **264 lines** of declarative YAML that provisions **15+ AWS resources** as a single atomic stack.

### 1. VPC & Networking

```yaml
# Custom VPC with DNS support
VPC:
  Type: AWS::EC2::VPC
  Properties:
    CidrBlock: 10.0.0.0/16
    EnableDnsSupport: true
    EnableDnsHostnames: true
```

**What's Provisioned:**

| Resource | Configuration | Purpose |
|:---------|:-------------|:--------|
| **VPC** | `10.0.0.0/16` (65,536 IPs) | Isolated network boundary for all resources |
| **Internet Gateway** | Attached to VPC | Enables inbound/outbound internet traffic |
| **Public Subnet 1** | `10.0.1.0/24` — AZ-1 | Hosts ALB and ECS tasks (256 IPs) |
| **Public Subnet 2** | `10.0.2.0/24` — AZ-2 | Second AZ for high availability (256 IPs) |
| **Route Table** | `0.0.0.0/0` → IGW | Routes all public traffic through the Internet Gateway |
| **Subnet Associations** | Both subnets → Route Table | Associates subnets with the public route table |

**Why Two Subnets?**
- ALB **requires** a minimum of two subnets across different Availability Zones
- Ensures the application survives an entire AZ failure (high availability)
- ECS tasks are distributed across both subnets

**Why `MapPublicIpOnLaunch: true`?**
- Fargate tasks with `AssignPublicIp: ENABLED` need public IPs to pull images from ECR
- This avoids the cost and complexity of NAT Gateways in a development/demo environment

---

### 2. IAM Roles & Security

Two distinct IAM roles enforce the **principle of least privilege**:

```
┌──────────────────────────────────────────────────────────────────┐
│                     ECS Task Execution Role                      │
│  WHO:  ecs-tasks.amazonaws.com (service principal)              │
│  WHAT: AmazonECSTaskExecutionRolePolicy (AWS managed)           │
│  WHY:  Allows ECS agent to pull images from ECR,                │
│        push logs to CloudWatch, and retrieve secrets             │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                        ECS Task Role                             │
│  WHO:  ecs-tasks.amazonaws.com (service principal)              │
│  WHAT: Custom policy — logs:CreateLogStream, logs:PutLogEvents  │
│  WHY:  Runtime permissions for the application container;        │
│        scoped to only the logging actions it actually needs      │
└──────────────────────────────────────────────────────────────────┘
```

| Role | Type | Permissions | Scope |
|:-----|:-----|:------------|:------|
| **ECSTaskExecutionRole** | Execution Role | Pull ECR images, push CloudWatch logs, read Secrets Manager | Infrastructure plane (used by ECS agent) |
| **ECSTaskRole** | Task Role | `logs:CreateLogStream`, `logs:PutLogEvents` | Application plane (used by your container) |

> **Security Note:** The Execution Role is the "infrastructure admin" — it operates on behalf of the ECS service. The Task Role is the "application identity" — it defines what your running code can access. Separating these follows AWS best practices for defense in depth.

---

### 3. Application Load Balancer (ALB)

The ALB serves as the single entry point for all incoming HTTP traffic and distributes it across healthy ECS tasks.

```
Internet Traffic (Port 80)
        │
        ▼
┌───────────────────────────────────────┐
│      Application Load Balancer        │
│      (Layer 7 — HTTP)                 │
│                                       │
│  Security Group: Allow 80 from 0.0.0.0│
└───────────┬───────────────┬───────────┘
            │               │
   ┌────────▼────────┐  ┌──▼───────────────┐
   │ Target Group     │  │ Target Group      │
   │ BLUE (Active)    │  │ GREEN (Standby)   │
   │                  │  │                   │
   │ Health Check: /  │  │ Health Check: /   │
   │ Interval: 30s    │  │                   │
   │ Timeout: 5s      │  │                   │
   │ Healthy: 2       │  │                   │
   │ Unhealthy: 2     │  │                   │
   └──────────────────┘  └───────────────────┘
```

**Key Configuration Details:**

- **Listener Rule:** Port 80 HTTP → Forward to Blue Target Group
- **Target Type:** `ip` (required for Fargate's `awsvpc` network mode)
- **Health Check:** `GET /` — the app's root endpoint returns JSON with status 200
- **Health Check Tuning:** 30s interval, 5s timeout, 2 consecutive checks for healthy/unhealthy transitions
- **Two Target Groups:** Blue (active) and Green (standby) enable zero-downtime deployments

---

### 4. ECS Fargate Cluster

```yaml
TaskDefinition:
  Type: AWS::ECS::TaskDefinition
  Properties:
    Cpu: 256          # 0.25 vCPU
    Memory: 512       # 512 MB
    NetworkMode: awsvpc
    RequiresCompatibilities:
      - FARGATE
```

**ECS Configuration Breakdown:**

| Setting | Value | Explanation |
|:--------|:------|:------------|
| **Launch Type** | `FARGATE` | Serverless — no EC2 instances to provision, patch, or scale |
| **Desired Count** | `2` | Two tasks running simultaneously for high availability |
| **CPU** | `256` (0.25 vCPU) | Minimal compute for a lightweight Node.js API |
| **Memory** | `512` MB | Sufficient for Express.js with low traffic |
| **Network Mode** | `awsvpc` | Each task gets its own ENI and private IP (required for Fargate) |
| **Container Port** | `80` | Matches the Express.js server listen port |
| **Log Driver** | `awslogs` | Ships stdout/stderr to CloudWatch Logs automatically |
| **AssignPublicIp** | `ENABLED` | Tasks can pull images from ECR without a NAT Gateway |

**Why Fargate over EC2?**
- No need to manage, scale, or patch EC2 instances
- Pay only for the exact CPU and memory your tasks consume
- Automatic bin-packing and task placement
- Ideal for microservices and intermittent workloads

---

### 5. Amazon ECR

The GitHub Actions workflow pushes Docker images to a private ECR repository:

```yaml
ECR_REPOSITORY: ci-cd-pipeline-repo
IMAGE_TAG: ${{ github.sha }}   # Every image is tagged with the commit SHA
```

**Image Lifecycle:**
1. **Build** — Multi-stage Dockerfile creates a minimal production image
2. **Tag** — Image tagged with the Git commit SHA for full traceability
3. **Push** — Pushed to private ECR repo with encryption at rest
4. **Pull** — ECS Fargate tasks pull the image using the Execution Role

**Why commit SHA as image tag?**
- Every deployment is **traceable** to an exact Git commit
- Easy to **rollback** by re-deploying a previous commit's image
- Avoids the pitfalls of mutable tags like `latest`

---

### 6. CloudWatch Logging

```yaml
LogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: /ecs/ci-cd-pipeline-app
    RetentionInDays: 14
```

- All container stdout/stderr is automatically shipped to CloudWatch via the `awslogs` log driver
- Logs are **prefixed** with `ecs` for easy filtering in the CloudWatch console
- **14-day retention** balances observability needs with cost optimization
- Log streams are organized by ECS task ID for easy debugging

---

## 🔄 CI/CD Pipeline Workflow

The pipeline is defined in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) and is triggered automatically on every push to the `main` branch.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PIPELINE STAGES                              │
│                                                                     │
│  ┌─────────────┐                                                    │
│  │   TRIGGER    │  Push to `main` branch                            │
│  └──────┬──────┘                                                    │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  STAGE 1: TEST                                              │    │
│  │  ┌─────────────────────────────────────────────────────┐    │    │
│  │  │ 1. Checkout code                                     │    │    │
│  │  │ 2. Setup Node.js 20                                  │    │    │
│  │  │ 3. npm ci (install locked dependencies)              │    │    │
│  │  │ 4. npm test (Jest + Supertest)                       │    │    │
│  │  │    ├── GET / → 200 + JSON body assertion             │    │    │
│  │  │    └── GET /health → 200 + "OK" assertion            │    │    │
│  │  └─────────────────────────────────────────────────────┘    │    │
│  └──────────────────────────┬──────────────────────────────────┘    │
│                             │ ✅ Tests pass                         │
│                             ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  STAGE 2: BUILD & DEPLOY                                    │    │
│  │  ┌─────────────────────────────────────────────────────┐    │    │
│  │  │ 1. Configure AWS Credentials (via GitHub Secrets)    │    │    │
│  │  │ 2. Login to Amazon ECR                               │    │    │
│  │  │ 3. Build Docker image (multi-stage)                  │    │    │
│  │  │ 4. Tag with commit SHA                               │    │    │
│  │  │ 5. Push to ECR                                       │    │    │
│  │  │ 6. Deploy CloudFormation stack (with new ImageUrl)   │    │    │
│  │  │    └── ECS service updates with new task definition  │    │    │
│  │  └─────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  🎯 Result: New version live on ALB endpoint                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Pipeline Jobs Explained

#### Job 1: `test`
| Step | Action | Purpose |
|:-----|:-------|:--------|
| Checkout | `actions/checkout@v3` | Pulls the latest code from the repository |
| Setup Node.js | `actions/setup-node@v3` | Installs Node.js 20 with npm caching for faster builds |
| Install Deps | `npm ci` | Clean install from lockfile (deterministic builds) |
| Run Tests | `npm test` | Runs Jest test suite; pipeline **fails fast** on test failure |

#### Job 2: `deploy` (runs only if `test` succeeds)
| Step | Action | Purpose |
|:-----|:-------|:--------|
| AWS Credentials | `aws-actions/configure-aws-credentials@v1` | Injects IAM credentials from GitHub Secrets into the runner |
| ECR Login | `aws-actions/amazon-ecr-login@v1` | Authenticates Docker daemon with ECR |
| Build & Push | Docker CLI | Builds multi-stage image, tags with commit SHA, pushes to ECR |
| Deploy Stack | `aws-actions/aws-cloudformation-github-deploy@v1` | Deploys/updates the CloudFormation stack with the new image URL |

---

## 🔵🟢 Blue/Green Deployment Strategy

This project is architected for **blue/green deployments** with two target groups:

```
                    ┌─────────────────────────┐
                    │         ALB             │
                    │    HTTP Listener :80     │
                    └───────┬─────────┬───────┘
                            │         │
             ┌──────────────▼──┐  ┌───▼──────────────┐
             │  BLUE (v1.0.0)  │  │  GREEN (v2.0.0)  │
             │  ◀── Active     │  │  ◀── Standby     │
             │  Tasks: 2       │  │  Tasks: 0        │
             └─────────────────┘  └──────────────────┘

  Step 1: Deploy new version to GREEN target group
  Step 2: Validate health checks pass
  Step 3: Switch ALB listener to GREEN
  Step 4: Old BLUE tasks drain and terminate
  Step 5: GREEN becomes the new BLUE for next deploy
```

**Benefits:**
- **Zero downtime** — traffic switches atomically from old to new version
- **Instant rollback** — if issues are detected, switch the listener back
- **Full validation** — new version is health-checked before receiving live traffic

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version | Installation |
|:-----|:--------|:-------------|
| **AWS CLI** | v2.x | [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| **Docker** | 20.x+ | [Install Guide](https://docs.docker.com/get-docker/) |
| **Node.js** | 20.x | [Install Guide](https://nodejs.org/) |
| **Git** | 2.x+ | [Install Guide](https://git-scm.com/) |

### Local Development

```bash
# Clone the repository
git clone https://github.com/ilahi123/aws-devops-production-pipeline.git
cd aws-devops-production-pipeline

# Install dependencies
cd app
npm install

# Run the application locally
npm start
# Server listening on port 80

# Run tests
npm test
```

### Deploy to AWS

#### Option A: Automated (GitHub Actions) — Recommended

1. **Configure GitHub Secrets** in your repository settings:

   | Secret Name | Description |
   |:------------|:------------|
   | `AWS_ACCESS_KEY_ID` | IAM user access key with ECS, ECR, CloudFormation, and IAM permissions |
   | `AWS_SECRET_ACCESS_KEY` | Corresponding secret access key |

2. **Create the ECR repository** (one-time setup):
   ```bash
   aws ecr create-repository \
     --repository-name ci-cd-pipeline-repo \
     --region ap-south-1
   ```

3. **Push to `main`** — the pipeline triggers automatically:
   ```bash
   git add .
   git commit -m "deploy: initial release"
   git push origin main
   ```

4. **Monitor** the pipeline in the GitHub Actions tab.

5. **Access your app** via the ALB DNS name (found in CloudFormation Outputs):
   ```bash
   aws cloudformation describe-stacks \
     --stack-name ci-cd-main-stack \
     --query "Stacks[0].Outputs[?OutputKey=='ALBEndpoint'].OutputValue" \
     --output text
   ```

#### Option B: Manual (Shell Scripts)

```bash
# Set up environment variables
cp .env.example .env
# Edit .env with your AWS credentials and configuration

# Deploy infrastructure + application
cd scripts
bash deploy.sh

# The script will output the ALB endpoint when complete
```

### Tear Down

> ⚠️ **Warning:** This permanently deletes all infrastructure and data.

```bash
cd scripts
bash destroy.sh
```

This script:
1. Initiates `aws cloudformation delete-stack`
2. Waits for stack deletion to complete (`stack-delete-complete`)
3. Removes all provisioned resources (VPC, subnets, ALB, ECS cluster, etc.)

---

## ⚙️ Environment Variables

| Variable | Default | Description |
|:---------|:--------|:------------|
| `AWS_ACCESS_KEY_ID` | — | IAM access key for AWS API authentication |
| `AWS_SECRET_ACCESS_KEY` | — | IAM secret key for AWS API authentication |
| `AWS_REGION` | `ap-south-1` | AWS region for all resources (Mumbai) |
| `NODE_ENV` | `development` | Node.js environment mode |
| `APP_PORT` | `80` | Port the Express.js server listens on |
| `ENVIRONMENT_NAME` | `ci-cd-pipeline` | Prefix for all AWS resource names |
| `ECS_CLUSTER_NAME` | `ci-cd-pipeline-cluster` | Name of the ECS cluster |
| `MAIN_STACK` | `ci-cd-main-stack` | CloudFormation stack name |

---

## 📡 API Endpoints

| Method | Path | Response | Purpose |
|:-------|:-----|:---------|:--------|
| `GET` | `/` | `{ "message": "Hello from the AWS CI/CD Pipeline App!", "version": "1.0.0", "environment": "development" }` | Main application endpoint |
| `GET` | `/health` | `OK` (200) | ALB health check endpoint |

### Example Request

```bash
# Using the ALB DNS name
curl http://<alb-dns-name>/

# Response
{
  "message": "Hello from the AWS CI/CD Pipeline App!",
  "version": "1.0.0",
  "environment": "development"
}
```

---

## 🧪 Testing

The project uses **Jest** as the test runner and **Supertest** for HTTP assertion testing.

```bash
cd app
npm test
```

**Test Suite:**

| Test | Assertion | What It Validates |
|:-----|:----------|:------------------|
| `GET /` | Status 200 + JSON body has `message` property | Main endpoint returns expected payload |
| `GET /health` | Status 200 + body equals `"OK"` | Health check endpoint works for ALB |

**Why Supertest?**
- Tests the Express.js app **without starting the server** (`require.main === module` guard)
- Simulates real HTTP requests for integration-level confidence
- Runs entirely in-memory — fast and CI-friendly

---

## 🔐 Security Best Practices

This project implements several AWS security best practices:

| Practice | Implementation |
|:---------|:---------------|
| **Least Privilege IAM** | Separate Execution Role and Task Role with minimal permissions |
| **No SSH Access** | Fargate tasks have no SSH daemon; debug via CloudWatch Logs and ECS Exec |
| **Security Group Isolation** | ECS tasks only accept traffic from the ALB security group (not the internet) |
| **Private ECR Registry** | Docker images stored in a private, encrypted-at-rest registry |
| **Secrets in GitHub Secrets** | AWS credentials stored as encrypted GitHub Secrets, never in code |
| **`.gitignore` for `.env`** | Environment file with credentials excluded from version control |
| **Multi-Stage Docker Build** | Production image contains only runtime dependencies (smaller attack surface) |
| **DNS Hostnames Enabled** | VPC DNS resolution for internal service discovery |

---

## 💰 Cost Optimization

| Resource | Estimated Monthly Cost | Optimization Applied |
|:---------|:----------------------|:--------------------|
| **ECS Fargate** (2 tasks × 0.25 vCPU, 512 MB) | ~$15-20 | Minimum viable compute for demo workload |
| **Application Load Balancer** | ~$16-22 | Single ALB shared across target groups |
| **CloudWatch Logs** | ~$0.50-1 | 14-day retention limit reduces storage costs |
| **ECR** | ~$0.10-1 | Only stores actively used images |
| **VPC / Networking** | $0 | No NAT Gateway (public subnets + public IPs instead) |
| **Total Estimated** | **~$32-44/month** | |

> 💡 **Tip:** For production workloads, consider Fargate Spot (up to 70% savings), Reserved Pricing, or ECS with EC2 Auto Scaling for higher traffic volumes.

---

## 🔧 Troubleshooting

<details>
<summary><b>❌ CloudFormation Stack Creation Failed</b></summary>

```bash
# Check stack events for the specific failure reason
aws cloudformation describe-stack-events \
  --stack-name ci-cd-main-stack \
  --query "StackEvents[?ResourceStatus=='CREATE_FAILED']"

# Common causes:
# - IAM permissions insufficient → Ensure your IAM user has CloudFormation, ECS, EC2, IAM, and ELB permissions
# - ECR repository doesn't exist → Create it first with `aws ecr create-repository`
# - Resource limit reached → Check your AWS account service limits
```
</details>

<details>
<summary><b>❌ ECS Tasks Not Starting</b></summary>

```bash
# Check task stopped reason
aws ecs describe-tasks \
  --cluster ci-cd-pipeline-cluster \
  --tasks $(aws ecs list-tasks --cluster ci-cd-pipeline-cluster --query "taskArns[0]" --output text)

# Check CloudWatch logs
aws logs tail /ecs/ci-cd-pipeline-app --follow

# Common causes:
# - Image pull failure → Verify ECR repository name and Execution Role permissions
# - Container crash → Check application logs for Node.js errors
# - Health check failure → Ensure the `/` or `/health` endpoint returns 200
```
</details>

<details>
<summary><b>❌ ALB Returns 503 Service Unavailable</b></summary>

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Common causes:
# - No healthy targets → ECS tasks haven't passed health checks yet (wait ~60s)
# - Security group misconfiguration → Ensure ECS SG allows inbound from ALB SG
# - Container not listening on port 80 → Check APP_PORT configuration
```
</details>

<details>
<summary><b>❌ GitHub Actions Pipeline Failing</b></summary>

```bash
# Verify GitHub Secrets are configured correctly
# Go to Repository → Settings → Secrets and Variables → Actions

# Test AWS credentials locally
aws sts get-caller-identity

# Common causes:
# - Missing or incorrect AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
# - IAM user lacks required permissions (ecr:*, ecs:*, cloudformation:*, iam:PassRole)
# - npm test failures blocking the deploy job
```
</details>

---

## 🔮 Future Enhancements

- [ ] **HTTPS Support** — Add ACM certificate and HTTPS listener on port 443
- [ ] **Custom Domain** — Configure Route 53 hosted zone with ALB alias record
- [ ] **Auto Scaling** — Add ECS Service Auto Scaling based on CPU/memory utilization
- [ ] **CodeDeploy Integration** — Fully managed blue/green deployments with automatic rollback
- [ ] **Private Subnets + NAT Gateway** — Move ECS tasks to private subnets for enhanced security
- [ ] **Secrets Manager** — Inject application secrets at runtime via ECS task definition
- [ ] **WAF Integration** — Add AWS WAF rules to the ALB for DDoS and SQL injection protection
- [ ] **Monitoring Dashboard** — CloudWatch dashboard with ECS metrics, ALB latency, and error rates
- [ ] **Multi-Environment** — Separate stacks for `dev`, `staging`, and `production` environments
- [ ] **Terraform Migration** — Optionally migrate IaC from CloudFormation to Terraform for multi-cloud support

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  <b>Built with ❤️ using AWS, Docker, and GitHub Actions</b>
  <br/>
  <sub>Demonstrating end-to-end DevOps expertise with cloud-native AWS services</sub>
</p>
