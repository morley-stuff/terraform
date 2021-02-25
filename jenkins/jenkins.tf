resource "aws_spot_instance_request" "JenkinsMaster" {

    spot_price = "0.005"

    ami = "ami-0e1a69c81175d6bf2"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    security_groups = [
        aws_security_group.SecurityGroupSSH.id,
        aws_security_group.SecurityGroupWebServer.id
    ]
    wait_for_fulfillment = true
    key_name = "ssh-laptop"

    user_data = <<EOF
#!/bin/bash

# Update
yum -y update

# Install Docker
yum -y install docker
service docker start
usermod -a -G docker ec2-user

# Launch jenkins image
docker pull jenkins/jenkins:lts
docker run -d -p 80:8080 jenkins/jenkins:lts

EOF

}

resource "aws_lb" "load_balancer" {
    name = "JenkinsLoadBalancer"
    load_balancer_type = "application"
    security_groups = [ aws_security_group.SecurityGroupWebServer.id ]
    subnets = [ aws_subnet.subnet1.id, aws_subnet.subnet2.id ]
}

resource "aws_lb_target_group_attachment" "Target" {
    target_group_arn = aws_lb_target_group.target_group.id
    port = 80
    target_id = "${aws_spot_instance_request.JenkinsMaster.private_ip}"
}

resource "aws_lb_target_group" "target_group" {
    name = "JenkinsTargetGroup"
    target_type = "ip"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.morleystuff_vpc.id
    health_check {
      path = "/login"
    }
}

resource "aws_lb_listener" "http_listener" {
    load_balancer_arn = aws_lb.load_balancer.id
    port = 80 
    protocol = "HTTP"
    default_action {
        type = "redirect"
        redirect {
            host = "#{host}"
            path = "/#{path}"
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

resource "aws_lb_listener" "https_listener" {
    load_balancer_arn = aws_lb.load_balancer.id
    port = 443
    protocol = "HTTPS"
    certificate_arn = "arn:aws:acm:ap-southeast-2:365033114011:certificate/cb73021b-6107-47ec-8f0e-dc02dcb6ec25"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.target_group.id
    }
}

resource "aws_route53_record" "a_record" {
    zone_id = "ZT0O09PTBTJOV"
    name = "jenkins.morleystuff.com"
    type = "A"
    alias {
        zone_id = aws_lb.load_balancer.zone_id
        name = aws_lb.load_balancer.dns_name
        evaluate_target_health = false
    }
}