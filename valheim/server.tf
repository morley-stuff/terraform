data "aws_ami_ids" "ami_ids" {
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn*"]
    }

    filter {
        name = "root-device-type"
        values = ["ebs"]
    }
}

resource "aws_ebs_volume" "persistent_storage" {
    availability_zone = data.aws_subnet.subnet.availability_zone
    size = 10
    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_volume_attachment" "storage_attachment" {
    device_name = "/dev/xvdb"
    volume_id  =aws_ebs_volume.persistent_storage.id
    instance_id = aws_spot_instance_request.valheim_server.spot_instance_id
    skip_destroy = true
}

resource "aws_spot_instance_request" "valheim_server" {

    // Machine definition
    instance_type          = "t2.medium"
    ami                    = data.aws_ami_ids.ami_ids.ids[0]
    subnet_id              = var.subnet_id
    
    // Spot pricing
    spot_price             = "0.02"
    wait_for_fulfillment   = "true"
    
    // Security
    key_name               = "ssh-laptop-eu"
    vpc_security_group_ids = [
        aws_security_group.sg_ssh.id,
        aws_security_group.sg_valheim.id,
    ]

    // Initialization
    user_data = <<EOF
#!/bin/bash

# Update
yum -y update

# Install Docker
yum -y install docker
service docker start
usermod -a -G docker ec2-user

# Mount directory for data
mkdir /data
mount /dev/xvdb /data

# Launch Valheim image
docker pull lloesche/valheim-server
docker run -d \
    --name valheim-server \
    --cap-add=sys_nice \
    --stop-timeout 120 \
    -p 2456-2457:2456-2457/udp \
    -v /data/config:/config \
    -v /data/valheim:/opt/valheim \
    -e SERVER_NAME="MorleyStuff" \
    -e WORLD_NAME="Chain" \
    -e SERVER_PASS="password" \
    -e VALHEIM_PLUS="true" \
    lloesche/valheim-server

EOF

}