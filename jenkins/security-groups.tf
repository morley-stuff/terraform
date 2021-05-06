resource "aws_security_group" "sec_group_ssh" {
    description = "Allows for inbound traffic on SSH port from any ip"
    vpc_id      = aws_vpc.vpc.id
    egress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        protocol    = "tcp"
        from_port   = "22"
        to_port     = "22"
        cidr_blocks = ["0.0.0.0/0"]
    }
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group" "sec_group_web" {
    description = "Allows for inbound traffic on HTTP & HTTPS ports"
    vpc_id      = aws_vpc.vpc.id
    egress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        protocol    = "tcp"
        from_port   = "80"
        to_port     = "80"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        protocol    = "tcp"
        from_port   = "443"
        to_port     = "443"
        cidr_blocks = ["0.0.0.0/0"]
    }
    lifecycle {
        create_before_destroy = true
    }
}