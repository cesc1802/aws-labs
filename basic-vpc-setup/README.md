# AWS VPC Progressive Lab for Solutions Architect Professional Exam

This hands-on lab is designed to take you from foundational AWS VPC setup to complex, real-world architectures. Each section includes detailed steps, expected outcomes, troubleshooting, integration, cost optimization, and cleanup.

## 1. Basic VPC Setup

### Lab Goals

- Create a custom VPC.
- Add public/private subnets.
- Set up route tables and Internet Gateway.


### Steps

1. **Create a Custom VPC**
    - Go to AWS Console > VPC > Create VPC.
    - Name: `LabVPC`, IPv4 CIDR: `10.0.0.0/16`.
2. **Create Subnets**
    - Public: `10.0.1.0/24` (Name: `PublicSubnet1`)
    - Private: `10.0.2.0/24` (Name: `PrivateSubnet1`)
3. **Attach Internet Gateway**
    - VPC Dashboard > Internet Gateways > Create, attach to `LabVPC`.
4. **Route Table for Public Subnet**
    - Edit public route table to add route: Destination `0.0.0.0/0`, Target Internet Gateway.
5. **Launch EC2 Instances**
    - One in the public subnet, one in the private subnet.

### Expected Outcomes

- Public instance has internet access.
- Private instance does not have direct internet access.


## 2. Scaling to Enterprise-Level

### Lab Goals

- Multi-AZ deployment for HA.
- NAT Gateway for private subnets.
- Network ACLs and security groups for segmentation.


### Steps

1. **Add More Subnets**
    - `10.0.3.0/24` (Public, AZ2), `10.0.4.0/24` (Private, AZ2).
2. **Update Route Tables**
    - Associate new subnets appropriately.
    - Add a second route table for private subnets.
3. **Deploy NAT Gateway**
    - Place in a public subnet, attach Elastic IP.
    - Update private route table: add `0.0.0.0/0` route to NAT Gateway.
4. **Configure Network ACLs**
    - Create custom ACLs, restrict unwanted ports (e.g., block SSH from the internet).

### Expected Outcomes

- Private subnet EC2 can access internet (e.g., for yum updates) but cannot be accessed directly from internet.
- Cross-AZ resources can communicate for HA.


## 3. Common Troubleshooting Scenarios

### Scenarios \& Fixes

- **Public EC2 instance can't access internet:**
    - Check correct subnet, route table, IGW attachment, security group/outbound rules.
- **Private EC2 can't reach internet via NAT:**
    - Verify NAT Gateway deployed in public subnet, check route table, security group.
- **Resource in one subnet can't reach another:**
    - Review NACLs, Security Groups, confirm correct subnet associations.


### Hands-on:

- Purposely misconfigure security group/NACL/route and resolve.


## 4. AWS Service Integrations

### Lab Goals

- Connect VPC with selected AWS services.


### Steps

1. **VPC Endpoints (S3 Gateway Endpoint)**
    - VPC Dashboard > Endpoints > Create Endpoint for S3. Select private subnets.
2. **RDS Deployment**
    - Launch RDS instance in private subnet. Ensure security group allows app traffic only.
3. **Lambda in VPC**
    - Create lambda attached to private subnet; test S3 access via endpoint.

### Expected Outcomes

- Private resources access S3 over endpoint, not via internet.
- App-layer integration with RDS and Lambda.


## 5. Cost Optimization Techniques

### Practices

- **VPC Endpoints over NAT Gateways:** Use Gateway Endpoints for services like S3/DynamoDB instead of NAT for significant savings.
- **Smaller Subnet CIDRs:** Avoid oversizing subnets if not needed.
- **Bastion Host Shutdown:** Shut down or use Lambda SSH bastions to save EC2 hours.
- **Flow Logs On-Demand:** Enable VPC flow logs only for troubleshooting.


### Expected Outcomes

- Lower NAT Gateway data processing charges.
- Lower resource counts and unnecessary running costs.


## 6. Cleanup Procedures

### Steps

1. Terminate all EC2, RDS, Lambda resources.
2. Delete NAT Gateways (release Elastic IPs).
3. Delete Endpoints.
4. Detach and delete Internet Gateway.
5. Delete subnets, then VPC.
6. Verify all resources removed to avoid ongoing charges.

### Expected Outcomes

- No residual lab resources or billing impacts.


### Notes

- Throughout the lab, keep an *architecture diagram* and highlight changes.
- For each step, verify with CLI (`aws ec2 describe-*`) or Console when possible.
- Use AWS Cost Explorer to track cost impact before/after optimization.

Work through each section before advancing. This progression will make you confident in fundamental, troubleshooting, and advanced VPC tasks essential for the Solutions Architect Professional exam.