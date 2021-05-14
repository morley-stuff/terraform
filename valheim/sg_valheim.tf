resource "aws_security_group" "sg_valheim" {
    description = "Allows for traffic over valheim server port"
    vpc_id      = data.aws_subnet.subnet.vpc_id
    ingress {
        protocol    = "udp"
        from_port   = "2456"
        to_port     = "2456"
        cidr_blocks = ["0.0.0.0/0"]
    }
    lifecycle {
        create_before_destroy = true
    }
}