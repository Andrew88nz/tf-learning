terraform {
  required_version = ">= 0.12"
}

provider "aws" {
   region = "ap-southeast-2"
}
  
resource "aws_launch_configuration" "example" {
  image_id = data.aws_ami.AmazonLinux.image_id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  
    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              service httpd start
              chkconfig httpd on
              cd /var/www/html
              echo "<html><h1>WORD UP</h1></html>"  >  index.html
              EOF

# Required when using a launch configuration with an auto scaling group.
# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
lifecycle {
create_before_destroy = true
}
}

resource "aws_autoscaling_group" "foo" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  min_size = 2
  max_size = 10
  instance_refresh {
  strategy = "Rolling"
  }


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

resource "aws_security_group" "instance" {

  name = var.security_group_name

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Permit all egress"
    from_port = 0
    protocol = "-1"
    to_port = 0
  } 
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-example-instance"
}

 resource "aws_lb" "example" {
   name = "terraform-asg-example"
   load_balancer_type = "application"
   subnets = data.aws_subnet_ids.default.ids
   security_groups = [aws_security_group.alb.id]
 }

 resource "aws_lb_listener" "http" {
   load_balancer_arn = aws_lb.example.arn
   port = 80
   protocol = "HTTP"
   default_action {
     type = "fixed-response"

     fixed_response {
     content_type = "text/plain"
     message_body = "404: page gone AWOL"
     status_code = 404
     }
   }
 }

 resource "aws_security_group" "alb" {
   name = "terraform-exmple-alb"
    ingress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = var.server_port
      protocol = "tcp"
      to_port = var.server_port
    } 
    egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 0
      protocol = "-1"
      to_port = 0
    } 
 }
 
 resource "aws_lb_target_group" "asg" {
   name = "terraform-asg0example"
   port = var.server_port
   protocol = "HTTP"
   vpc_id = data.aws_vpc.default.id

   health_check {
     path= "/"
     protocol = "HTTP"
     matcher = "200"
     interval = 15
     timeout = 3
     healthy_threshold = 2
     unhealthy_threshold = 2
   }
 }
 resource "aws_lb_listener_rule" "asg" {
   listener_arn = aws_lb_listener.http.arn
   priority = 100

   condition {
     path_pattern {
       values = ["*"]
     }
   }
   action {
     type = "forward"
     target_group_arn = aws_lb_target_group.asg.arn
   }
 }


output "public_ip" {
  value       = aws_lb.example.dns_name
  description = "The DNS name of the ALB"
}
