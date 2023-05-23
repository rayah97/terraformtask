provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name                  = "my-vpc"
  cidr                  = "10.0.0.0/16"
  create_igw            = true 
  azs                   = ["us-east-1a"]
  private_subnets       = ["10.0.1.0/24"]
  public_subnets        = ["10.0.0.0/24"]
  enable_nat_gateway    = true
  vpc_tags = {
    Name = "my-igw"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
resource "aws_instance" "ec2_instance" {
  count                          = var.instance_count
  ami                            = var.instance_ami
  instance_type                  = var.instance_type
  subnet_id                      = module.vpc.private_subnets[0]
  associate_public_ip_address    = true
  security_groups                = [module.vpc.default_security_group_id]

  tags = {
    Name = "EC2 Instance ${count.index + 1}"
  }
}
resource "aws_elb" "lb" {
 name               = "example-lb"


 subnets = [
   module.vpc.public_subnets[0],
 ]


 listener {
   lb_port           = 80
   lb_protocol       = "http"
   instance_port     = 80
   instance_protocol = "http"
 }


 health_check {
   healthy_threshold   = 2
   unhealthy_threshold = 2
   timeout             = 3
   interval            = 30
   target              = "HTTP:80/"
 }


 instances = aws_instance.ec2_instance.*.id
}

