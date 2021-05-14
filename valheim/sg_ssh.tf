resource "aws_security_group" "sg_ssh" {
    description = "Allows for inbound traffic on SSH port from any ip"
    vpc_id      = data.aws_subnet.subnet.vpc_id
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