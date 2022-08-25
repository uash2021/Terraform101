terraform {
  cloud {
    organization = "NoodleDom"

    workspaces {
      name = "Provisioners"
    }
  } # here we can use different backend as well, I have used terraform Cloud as my backend

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.27.0"
    }
  }
}

provider "aws" {

    region = "us-east-1"
  
}

resource "aws_key_pair" "Aug22Key" {
  key_name   = "Aug22Key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCz7GcBFayNdvcaB3IuO+8IaUqfnhMVkTTxlbQvJB3dYy7RrfnrArNeLUWgykzMYHPviv/nChq17/dYASpm4A0XGlsD/YsO+26Bi3T+pZaYm1xsdPyGn5DnkHo3ocKKyiAxWEYVZPTW3fZ0mnaCsUOzt0fw/HPpa3/nZgVEE6VvTf5FwXm1+7pESZiqPJ3TO4iq2pHQoFKwngo+ZQGfy9jV5tIBPyNT91uGBV6slMqolAdzN1jdIbkxu0jH4xKl1/2MGrOHtnyAB8sFiOxwFouCEXxQHog+Qt54U3/P5lBzuXrATyR+PL7o4RjK2iOkjn/aw1srwRjqntY/xows4IXV+sY79ZgKK2HYydy2TagYqwITutD+Wl0mMEwdHqBRFD33EDT8t74QBVrGCbcoiTgt+S2PaXNFkA2vVtDefb5sHYBTQhno2cMxQJPku5KpUoKPoj038zUfsQMdZspkgc32jdzgjPiyUzbK8stS1V/tmbAOj6DAmYfsUy1NOpsKeDE= ubedullah@LAPTOP-RAI1P90O"
}
#Create a key pair using SSH and paste public key here and use the private key to login via ssh

resource "aws_vpc" "mainvpc" {
  cidr_block = "10.1.0.0/16"
}

data "aws_vpc" "main" {
  id = "vpc-05de8c5755e8a81d6" # This is data source, used to refer in below block
}

resource "aws_security_group" "Aug22SG" {
  name        = "Aug22SG"
  description = "My SG for server"
  vpc_id      = data.aws_vpc.main.id

  ingress = [
    {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false
  },
  {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["49.205.245.115/32"]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false
  }
  ]

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  }
  }

  data "template_file" "user_data"{
    template = file("./userdata.yaml")
  }# this is data source template file used to accept a file, give path of the file and name it


resource "aws_instance" "app_server" {
  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.Aug22Key.key_name}"
  vpc_security_group_ids = [aws_security_group.Aug22SG.id]
  user_data = data.template_file.user_data.rendered # mandatory syntax to refer the file

    provisioner "file" {
    content     = "Mars"
    destination = "/home/ec2-user/barsoon.txt"
  }# This is file Provisioner which is used to copy file from local to server created
 
  /*provisioner "remote-exec" {
    inline = [
      "echo ${self.private_ip} >> /home/ec2-user/private_ips.txt" #This will run all the commands on the server provided in the inline block
    ]
    
  }*/ # This is remote exec Provisioner block, which can be used to execute commands or inline script or scripts on the server.

  connection {
    type = "ssh"
    user = "ec2-user"
    host = "${self.public_ip}"
    private_key = "${file("./terraform")}"
    
  }# This is mandatory block which is needed to provided details of connection to the remote server created
  tags = {

    Name = "AugServer"
  }
}

output "public_ip" {
  value = aws_instance.app_server.public_ip
}
