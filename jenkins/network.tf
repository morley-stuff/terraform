provider "aws" {
    profile = "default"
    region  = "ap-southeast-2"
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "inet_gateway" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route" {
    vpc_id = aws_vpc.vpc.id

    route {
        gateway_id = aws_internet_gateway.inet_gateway.id
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_network_acl" "nacl" {
    vpc_id = aws_vpc.vpc.id

    subnet_ids = [
        aws_subnet.subnet1.id,
        aws_subnet.subnet2.id
    ]

    egress {
        action     = "allow"
        rule_no    = "100"
        from_port  = "0"
        to_port    = "0"
        protocol   = "-1"
        cidr_block = "0.0.0.0/0"
    }

    ingress {
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = "22"
        protocol   = "tcp"
        rule_no    = "100"
        to_port    = "22"
    }
    ingress {
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = "80"
        protocol   = "tcp"
        rule_no    = "101"
        to_port    = "80"
    }
    ingress {
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = "443"
        protocol   = "tcp"
        rule_no    = "102"
        to_port    = "443"
    }
    ingress {
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = "1024"
        protocol   = "tcp"
        rule_no    = "103"
        to_port    = "65535"
    }
    
}

resource "aws_subnet" "subnet1" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.0.0/26"
    availability_zone_id    = "apse2-az1"
    map_public_ip_on_launch = "true"
}

resource "aws_subnet" "subnet2" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.0.128/26"
    availability_zone_id    = "apse2-az3"
    map_public_ip_on_launch = "true"
}

resource "aws_route_table_association" "subnet1_route" {
    subnet_id      = aws_subnet.subnet1.id
    route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "subnet2_route" {
    subnet_id      = aws_subnet.subnet2.id
    route_table_id = aws_route_table.route.id
}