resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/24"
    tags = {
        # Tag to indicate that this is the main vpc for the region
        name = "morleystuff_vpc"
    }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet1" {
    vpc_id                  = aws_vpc.vpc.id
    availability_zone       = data.aws_availability_zones.available.names[0]
    cidr_block              = "10.0.0.0/26"
    map_public_ip_on_launch = "true"
}

resource "aws_subnet" "subnet2" {
    vpc_id                  = aws_vpc.vpc.id
    availability_zone       = data.aws_availability_zones.available.names[1]
    cidr_block              = "10.0.0.128/26"
    map_public_ip_on_launch = "true"
}

output "vpc_id" {
    value = aws_vpc.vpc.id
}

output "subnet1_id" {
    value = aws_subnet.subnet1.id
}

output "subnet2_id" {
    value = aws_subnet.subnet2.id
}
