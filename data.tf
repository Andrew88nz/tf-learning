data "aws_vpc" "default" {
  default=true
}
data "aws_subnet_ids" "default" {
   vpc_id = data.aws_vpc.default.id
 }

# data "aws_subnet_ids" "defaultvpc" {
#   vpc_id = var.vpc_id
# }

# data "aws_subnet" "defaultsn" {
  # for_each = data.aws_subnet_ids.default.ids
  # id       = each.value
# }

data "aws_ami" "AmazonLinux"  {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}