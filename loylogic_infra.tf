terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Creating a New Key
resource "aws_key_pair" "Key-Pair" {

  # Name of the Key
  key_name = "MyKey"

  # Adding the SSH authorized key !
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2JATOXdmQNsvtAwHgobCE+94X25v5XIefY3vtYgQKEGBH4kBigvz8PV5lRLHt7/OLywqXHM07UGSGPxqbw1Lh21f7rVSZo7Q5wnmdQOo6aSzhkz/Lm8JGtS9nbxcSU1IDqMHskqoc3d0MKyBRY5wf7I/r5hAtGcA4QZ4mUe5d9jD7F1JEX5bgE6otrXSv3QKseRiTGNKpvhDoCb9uU/AmOOTZO/Uf5nazsCuUtrvg0GylAmVxUxCKMl5wLQdS+gdZmkIGtJA0gg2r4vU8Hv/bf9VtHFT/DCVDkgoIwC2D8RdO5epkHODllR9qk5JmtkC0K7AceCsxy3C+EhwXKfolxBeVKu8+Etud8k8/b8u3NXCMjLaIcjCbZi1hwwJHz4T36/C7mjyaArTzX8aNlio5i9MVNKjdYwGz25n9/+x1VGdW1U6HVwgg5EmaeTm7mEQ9jBHAL485H8BAUSUd501CT6ncgiIjSu4JRsj80OQrlTLDAA+O68gEgWVdzkqb8v0= rajender@raj"

}


# Creating a VPC!
resource "aws_vpc" "loylogic" {

  # IP Range for the VPC
  cidr_block = "172.20.0.0/16"

  # Enabling automatic hostname assigning
  enable_dns_hostnames = true
  tags = {
    Name = "loylogic"
  }
}


# Creating Public subnet!
resource "aws_subnet" "subnet1" {
  depends_on = [
    aws_vpc.loylogic
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.loylogic.id

  # IP Range of this subnet
  cidr_block = "172.20.10.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-1a"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}


# Creating Public subnet!
resource "aws_subnet" "subnet2" {
  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.loylogic.id

  # IP Range of this subnet
  cidr_block = "172.20.20.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private Subnet"
  }
}


# Creating an Internet Gateway for the VPC
resource "aws_internet_gateway" "Internet_Gateway" {
  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  # VPC in which it has to be created!
  vpc_id = aws_vpc.loylogic.id

  tags = {
    Name = "IG-Public-&-Private-VPC"
  }
}

# Creating an Route Table for the public subnet!
resource "aws_route_table" "Public-Subnet-RT" {
  depends_on = [
    aws_vpc.loylogic,
    aws_internet_gateway.Internet_Gateway
  ]

  # VPC ID
  vpc_id = aws_vpc.loylogic.id

  # NAT Rule
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = {
    Name = "Route Table for Internet Gateway"
  }
}

# Creating a resource for the Route Table Association!
resource "aws_route_table_association" "RT-IG-Association" {

  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_route_table.Public-Subnet-RT
  ]

  # Public Subnet ID
  subnet_id = aws_subnet.subnet1.id

  #  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}


# Creating an Elastic IP for the NAT Gateway!
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.RT-IG-Association
  ]
  vpc = true
}


# Creating a NAT Gateway!
resource "aws_nat_gateway" "NAT_GATEWAY" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP
  ]

  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id

  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.subnet1.id
  tags = {
    Name = "Nat-Gateway_loylogic"
  }
}


# Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "NAT-Gateway-RT" {
  depends_on = [
    aws_nat_gateway.NAT_GATEWAY
  ]

  vpc_id = aws_vpc.loylogic.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GATEWAY.id
  }

  tags = {
    Name = "Route Table for NAT Gateway"
  }

}


# Creating an Route Table Association of the NAT Gateway route 
# table with the Private Subnet!
resource "aws_route_table_association" "Nat-Gateway-RT-Association" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

  #  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id = aws_subnet.subnet2.id

  # Route Table ID
  route_table_id = aws_route_table.NAT-Gateway-RT.id
}

# Creating a Security Group for WordPress
resource "aws_security_group" "JENKINS-SG" {

  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group!
  name = "jenkins-sg"

  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.loylogic.id

  # Created an inbound rule for webserver access!
  ingress {
    description = "HTTP for webserver"
    from_port   = 80
    to_port     = 8080

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the WordPress
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating security group for MySQL, this will allow access only from the instances having the security group created above.
resource "aws_security_group" "MYAPP-SG" {

  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.JENKINS-SG
  ]

  description = "MySQL Access only from the Webserver Instances!"
  name        = "myapp-sg"
  vpc_id      = aws_vpc.loylogic.id

  # Created an inbound rule for MySQL
  ingress {
    description     = "MyApp Access"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.JENKINS-SG.id]
  }

  egress {
    description = "output from MyApp"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating security group for Bastion Host/Jump Box
resource "aws_security_group" "Bastion-SG" {

  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  description = "MyApp Access only from the Webserver Instances!"
  name        = "bastion-host-sg"
  vpc_id      = aws_vpc.loylogic.id

  # Created an inbound rule for Bastion Host SSH
  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from Bastion Host"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating security group for MyApp Bastion Host Access
resource "aws_security_group" "APP-SG-SSH" {

  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.Bastion-SG
  ]

  description = "MyApp Bastion host access for updates!"
  name        = "mysql-sg-bastion-host"
  vpc_id      = aws_vpc.loylogic.id

  # Created an inbound rule for MySQL Bastion Host
  ingress {
    description     = "Bastion Host SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.Bastion-SG.id]
  }

  egress {
    description = "output from MySQL Bastion"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating an AWS instance for the Jenkins!
resource "aws_instance" "jenkins" {

  depends_on = [
    aws_vpc.loylogic,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.Bastion-SG,
    aws_security_group.APP-SG-SSH
  ]

  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "MyKey"

  # Security groups to use!
  vpc_security_group_ids = [aws_security_group.JENKINS-SG.id]

  # Installing required softwares into the system!
  #connection {
  #  type = "ssh"
  #  user = "ec2-user"
  #  private_key = file("/Users/harshitdawar/Github/AWS-CLI/MyKeyFinal.pem")
  #  host = aws_instance.webserver.public_ip
  #}

  user_data = file("Install_Jenkins_Ansible_Docker.sh")

  tags = {
    Name = "Jenkins_From_Terraform"
  }

}

# Creating an AWS instance for the MyApp! It should be launched in the private subnet!
resource "aws_instance" "MyApp" {
  depends_on = [
    aws_instance.jenkins,
  ]

  # i.e. MySQL Installed!
  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id

  # Keyname and security group are obtained from the reference of their instances created above!
  key_name = "MyKey"

  # Attaching 2 security groups here, 1 for the MySQL Database access by the Web-servers,
  # & other one for the Bastion Host access for applying updates & patches!
  vpc_security_group_ids = [aws_security_group.MYAPP-SG.id, aws_security_group.APP-SG-SSH.id]

  tags = {
    Name = "MyApp_From_Terraform"
  }
}


# Creating an AWS instance for the Bastion Host, It should be launched in the public Subnet!
resource "aws_instance" "Bastion-Host" {
  depends_on = [
    aws_instance.jenkins,
    aws_instance.MyApp
  ]

  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above!
  key_name = "MyKey"

  # Security group ID's
  vpc_security_group_ids = [aws_security_group.Bastion-SG.id]
  tags = {
    Name = "Bastion_Host_From_Terraform"
  }
}