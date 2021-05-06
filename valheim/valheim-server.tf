provider "aws" {
    profile = "default"
    region  = "eu-central-1"
}

resource "aws_spot_instance_request" "valheim_server" {

    // Machine definition
    instance_type        = "t2.medium"
    ami                  = "ami-0233214e13e500f77"
    subnet_id            = aws_subnet.subnet1.id
    
    // Spot pricing
    spot_price           = "0.02"
    wait_for_fulfillment = "true"
    
    // Security
    key_name             = "ssh-laptop-eu"
    security_groups      = [
        aws_security_group.sec_group_ssh.id,
        aws_security_group.sec_group_web.id,
        aws_security_group.sec_group_valheim.id
    ]
}

resource "aws_route53_record" "a_record" {
    zone_id = "ZT0O09PTBTJOV"
    name    = "valheim.morleystuff.com"
    type    = "A"
    ttl     = "300"
    records = [aws_spot_instance_request.valheim_server.public_ip]
}