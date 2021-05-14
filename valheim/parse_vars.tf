variable "subnet_id" {
    type = string
}

data "aws_subnet" "subnet" {
    id = var.subnet_id
}