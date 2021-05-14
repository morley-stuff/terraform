resource "aws_internet_gateway" "inet_gateway" {
    vpc_id = aws_vpc.vpc.id
}

# Route everything through inet gateways
resource "aws_route_table" "route" {
    vpc_id = aws_vpc.vpc.id

    route {
        gateway_id = aws_internet_gateway.inet_gateway.id
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_route_table_association" "subnet1_route" {
    subnet_id      = aws_subnet.subnet1.id
    route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "subnet2_route" {
    subnet_id      = aws_subnet.subnet2.id
    route_table_id = aws_route_table.route.id
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
    ingress {
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = "2456"
        protocol   = "udp"
        rule_no    = "104"
        to_port    = "2456"
    }
}

