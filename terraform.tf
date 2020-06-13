provider "aws" {
  region  = "us-east-1"
  profile = "nagesh"
  
}


//create security group

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
 # vpc_id      = "vpc-b46031ce"
ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "log" {

value =aws_security_group.allow_tls

}

resource "aws_instance" "cli" {
  ami           = "ami-09d95fab7fff3776c"
  instance_type = "t2.micro"
  key_name = "lincli"
  security_groups = [ "allow_tls"  ]

  tags = {
    Name = "linux"
  }
}


resource "aws_ebs_volume" "vol" {
  availability_zone = aws_instance.cli.availability_zone
  size              = 1

  tags = {
    Name = "pd"
  }
}
resource "aws_volume_attachment" "vol" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.vol.id
  instance_id = aws_instance.cli.id
}



resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.vol,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:\\Users\\N A G E S H\\lincli.pem")
    host     = aws_instance.cli.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd git -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo mkdir /var/www/html",
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/nagesh1332/hybrid_task1.git /var/www/html/",

    ]
  }
}



//creating S3 bucket

resource "aws_s3_bucket" "TERRAFORM" {
  
  acl    = "public-read"
  versioning {
enabled=true
}
}


locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "comment"

}



//creating S3 bucket_object

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.TERRAFORM.bucket
  key    = "WEB_IMAGE"
  acl = "public-read"
  source="C:\\Users\\N A G E S H\\Downloads\\logo.png"
  etag = filemd5("C:\\Users\\N A G E S H\\Downloads\\logo.png")
}

// creating cloudfront for s3 bucket

resource "aws_cloudfront_distribution" "s3_distribution" {
origin {
    domain_name = aws_s3_bucket.TERRAFORM.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
enabled             = true
  is_ipv6_enabled     = true


default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
forwarded_values {
      query_string = false
cookies {
        forward = "none"
      }
    }
viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,aws_cloudfront_distribution.s3_distribution
  ]

	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.cli.public_ip}"
  	}
}