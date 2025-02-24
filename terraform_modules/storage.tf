#####################################
# EBS Volume for OpenVPN
#####################################
resource "aws_ebs_volume" "openvpn_ebs" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 10
  type              = "gp2"
  tags = {
    Name = "OpenVPN-Storage"
  }
}

resource "aws_volume_attachment" "openvpn_volume_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.openvpn_ebs.id
  instance_id = aws_instance.openvpn_server.id
}

#####################################
# EBS Volume for HAProxy
#####################################
resource "aws_ebs_volume" "haproxy_ebs" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 10
  type              = "gp2"
  tags = {
    Name = "HAProxy-Storage"
  }
}

resource "aws_volume_attachment" "haproxy_volume_attach" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.haproxy_ebs.id
  instance_id = aws_instance.haproxy_server.id
}
