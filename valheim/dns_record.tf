resource "aws_route53_record" "a_record" {
    zone_id = "ZT0O09PTBTJOV"
    name    = "valheim.morleystuff.com"
    type    = "A"
    ttl     = "300"
    records = [aws_spot_instance_request.valheim_server.public_ip]
}