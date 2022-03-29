provider "aws" {}


variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
# variable "my_pub_key" {}

resource "aws_vpc" "myapp_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
      "Name" = "${var.env_prefix}-vpc"
    }
}   
resource "aws_subnet" "myapp_subnet" {
    vpc_id =aws_vpc.myapp_vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone =  var.avail_zone
    tags = {
      "Name" = "${var.env_prefix}-subnet-1"
    }
    }
//creating internet gateway
resource "aws_internet_gateway" "myapp_ig" {
    vpc_id = aws_vpc.myapp_vpc.id
    tags = {
      
      "Name" = "${var.env_prefix}-Myapp_ig"
      }
  
}
//creating default route table and adding ig
resource "aws_default_route_table" "main_route_table" {
    default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
    route {
        cidr_block="0.0.0.0/0"
        gateway_id=aws_internet_gateway.myapp_ig.id
    
    }
    tags = {
      "Name" = "${var.env_prefix}-Myapp_route_table"
    }
  
}
//creating security group
resource "aws_security_group" "myapp_sg" {
  name = "my_app_sg"
  vpc_id = aws_vpc.myapp_vpc.id
  ingress {//for ssh
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]//handful of ip which are allowed to access
    }

  ingress {//for enginx
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {//for fetching stuff from internet etc
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }

  tags = {
    "Name" = "${var.env_prefix}-myapp_security_group"
  }
}

//creating ec2 instance
data "aws_ami" "amazon_linux_image" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

//creatring keypair 
# resource "aws_key_pair" "dev_key_pair" {
#   key_name   = "ssh_dev-key"
#   public_key =var.my_pub_key
# }
resource "aws_instance" "ec2_instance_web" {
  ami = data.aws_ami.amazon_linux_image.id
  instance_type = var.instance_type

  subnet_id= aws_subnet.myapp_subnet.id
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true//for accessing this from web
  key_name = "Dev_app_ssh_key"


  user_data ="${file("entry-script.sh")}"
  
  tags = {
      "Name" = "${var.env_prefix}-ec2_server"
    }

}


# output "aws_ami_id" {
#   value=data.aws_ami.amazon_linux_image
  
# }
//creating route table and connecting with ig for vpc
# resource "aws_route_table" "myapp_route_table" {
#     vpc_id = aws_vpc.myapp_vpc.id
#     route {
#         cidr_block="0.0.0.0/0"
#         gateway_id=aws_internet_gateway.myapp_ig.id
    
#     }
#     tags = {
#       "Name" = "${var.env_prefix}-Myapp_route_table"
#     }
      
# }
# //connecting route table with subnet
# resource "aws_route_table_association"  "Subnet_route_table" {
#     subnet_id= aws_subnet.myapp_subnet.id
#     route_table_id= aws_route_table.myapp_route_table.id
  
# }