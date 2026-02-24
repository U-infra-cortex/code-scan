provider "aws" {
  region = "ap-northeast-2"
}

variable "vpc_id"{
  default = "vpc-8fefe1e7"

}

//az1 subnet variable
variable "pa_az1_mgt_subnet_id"{
  default = "subnet-024bdbf0937d5792f"
}

variable "pa_az1_GWLB_subnet_id"{
  default = "subnet-0c43bb06836aa1273"
}

//az2 subnet variable
variable "pa_az2_mgt_subnet_id"{
  default = "subnet-024bdbf0937d5792f"
}

variable "pa_az2_GWLB_subnet_id"{
  default = "subnet-0c43bb06836aa1273"
}

//security group
resource "aws_security_group" "allow-mgt-sg-iac" {
  name        = "allow-pa-mgt-sg-iac"
  description = "Allow pa-sg-mgt-traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "allow-443"
    from_port        = 0
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "allow-22"
    from_port        = 0
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-pa-mgt-sg"
  }
}

resource "aws_security_group" "allow-pa-traffic-sg-iac" {
  name        = "allow-pa-traffic-sg-iac"
  description = "Allow pa-sg all traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "allow-pa-traffic-sg"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-pa-traffic-sg"
  }
}


resource "aws_eip" "pa1-mgt" {
  network_interface = aws_network_interface.pa-az1-mgt.id

  tags = {
    Name = "PA1-MGT-EIP"
  }
}

resource "aws_eip" "pa2-mgt" {
  network_interface = aws_network_interface.pa-az2-mgt.id

  tags = {
    Name = "PA2-MGT-EIP"
  }
}

//network interface
resource "aws_network_interface" "pa-az1-mgt" {
  subnet_id       = var.pa_az1_mgt_subnet_id
  security_groups = [aws_security_group.allow-mgt-sg-iac.id]
  description = "PA-AZ1-MGT"

  tags = {
    Name = "PA-AZ1-MGT"
  }
}
resource "aws_network_interface" "pa-az1-HA" {
  subnet_id       = var.pa_az1_mgt_subnet_id
  security_groups = [aws_security_group.allow-mgt-sg-iac.id]
  description = "PA-AZ1-HA"

  tags = {
    Name = "PA-AZ1-HA"
  }
}

resource "aws_network_interface" "pa-az1-GWLB" {
  subnet_id       = var.pa_az1_GWLB_subnet_id
  security_groups = [aws_security_group.allow-pa-traffic-sg-iac.id]
  source_dest_check = false
  description = "PA-AZ1-GWLB"

  tags = {
    Name = "PA-AZ1-GWLB"
  }
}

resource "aws_network_interface" "pa-az2-mgt" {
  subnet_id       = var.pa_az2_mgt_subnet_id
  security_groups = [aws_security_group.allow-mgt-sg-iac.id]
  description = "PA-AZ2-MGT"

  tags = {
    Name = "PA-AZ2-MGT"
  }
}
resource "aws_network_interface" "pa-az2-HA" {
  subnet_id       = var.pa_az2_mgt_subnet_id
  security_groups = [aws_security_group.allow-mgt-sg-iac.id]
  description = "PA-AZ2-HA"

  tags = {
    Name = "PA-AZ2-HA"
  }
}

resource "aws_network_interface" "pa-az2-GWLB" {
  subnet_id       = var.pa_az2_GWLB_subnet_id
  security_groups = [aws_security_group.allow-pa-traffic-sg-iac.id]
  source_dest_check = false
  description = "PA-AZ2-GWLB"

  tags = {
    Name = "PA-AZ2-GWLB"
  }
}


//instance
resource "aws_instance" "az1_paloalto" {
  ami = "ami-044f2706d439f1770"
  instance_type = "c5.xlarge"
  key_name = "juwon-aws-key-2023"
  availability_zone = "ap-northeast-2a"
  user_data = "mgmt-interface-swap=enable"

  network_interface {
    network_interface_id = aws_network_interface.pa-az1-mgt.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.pa-az1-GWLB.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 60

  }

  tags = {
    Name = "Paloalto_AZ1"
  }
}

resource "aws_instance" "az2_paloalto" {
  ami = "ami-044f2706d439f1770"
  instance_type = "c5.xlarge"
  key_name = "juwon-aws-key-2023"
  availability_zone = "ap-northeast-2a"
  user_data = "mgmt-interface-swap=enable"

    network_interface {
    network_interface_id = aws_network_interface.pa-az2-mgt.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.pa-az2-GWLB.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 60

  }

  tags = {
    Name = "Paloalto_AZ2"
  }

}