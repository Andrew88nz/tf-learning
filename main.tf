terraform {
  required_version = ">= 0.12"
}

provider "aws" {
   region = "ap-southeast-2"
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-0210560cedcb09f07"
  instance_type = "t2.micro"
  key_name = "ec2key"
  security_groups = [aws_security_group.instance.id]
  
    user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
}
# Required when using a launch configuration with an auto scaling group.
# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
lifecycle {
create_before_destroy = true
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  
  min_size = 2
  max_size = 10
  vpc_zone_identifier= [data.aws_subnet_ids.default]
  tag {
  key = "Name"
  value = "terraform-asg-example"
  propagate_at_launch = true
  }
  
}

# resource "aws_instance" "example" {
#   ami = "ami-0210560cedcb09f07"
#   instance_type = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   user_data = <<-EOF
#               #!/bin/bash
#               echo "Hello, World" > index.html
#               nohup busybox httpd -f -p ${var.server_port} &
#               EOF

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {

  name = var.security_group_name

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-example-instance"
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP of the Instance"
}
