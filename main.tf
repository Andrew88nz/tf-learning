provider "aws" {
  region = "ap-southeast-2"
}
resource "aws_instance" "example" {
  ami = "ami-0210560cedcb09f07"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF
  tags = {
      Name = "terrform-upandrunning"
  }
}
resource "aws_security_group" "instance" {
    name = "terraform-upandrunning-instance"

    ingress =  {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "HTTP Inbound"
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
    }
}