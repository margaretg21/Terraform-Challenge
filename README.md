# Terraform Network Setup Repository

This folder contains all of the code needed to create a simple VPC and the associated items.

The "modules" folder contains all of the module-specific code implemented in main.tf. The modules can be found below:

Networking: this module contains information surrounding the VPC, subnet, and internet gateway setup

EC2: this module contains code used to set up an EC2 instance running RedHat in the public subnet

ASG: this module contains code creating an auto scaling group in the private subnet
  - The ASG has been continually getting the error "Launching a new EC2 instance. Status Reason: Max spot instance count exceeded. Launching EC2 instance failed." This error was
    resolved on 6/15 by implementing a Mixed Instance Policy and 2 instances were created and became the target group for the ALB, but in fixing the outdated launch template and 
    updating tha AMI to RedHat the policy ceased to work. I spent a good amount of time on Stack Overflow, the Terraform and AWS websites, and github looking at other module code
    and was unable to fix within the time limit without breaking the code more aggregiously.
  - Within the time limit I was unable to install Apache, but did spend a good amount of time researching and feel that with a little more time this could be achieved.
  
ALB: this module contains code creating the load balancer in front of the ASG
  - The target group arn matches the ASG arn - once the mixed policy is updated the target group should fill in as needed.
  
S3: this module contains code creating an S3 bucket comlete with lifecycle policies on both folders

ssh-key: this module creates the key used to log into the EC2 instance and saves it to a local folder
