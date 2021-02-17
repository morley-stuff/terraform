// S3 Bucket hosting static site
resource "aws_s3_bucket" "deploy_bucket" {
    website {
      index_document = "index.html"
      error_document = "index.html"
    }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "TF complains if undefined"
}

// CloudFront distribution serving / caching contents of our static site
resource "aws_cloudfront_distribution" "morleystuff-cloudfront" {
    origin {
        s3_origin_config {
          origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
        }
        domain_name = aws_s3_bucket.deploy_bucket.bucket_regional_domain_name
        origin_id = aws_s3_bucket.deploy_bucket.id
    }
    aliases = [ "morleystuff.com", "*.morleystuff.com" ]
    viewer_certificate {
        acm_certificate_arn = "arn:aws:acm:us-east-1:365033114011:certificate/9f4ffc76-18d3-41e8-ba82-1aca7cc12ebf"
        ssl_support_method = "sni-only"
    }
    default_root_object = "index.html"
    custom_error_response {
        error_code = 403
        response_code = 200
        response_page_path = "/index.html"
    }
    custom_error_response {
        error_code = 404
        response_code = 200
        response_page_path = "/index.html"
    }
    default_cache_behavior {
        min_ttl = 86400
        default_ttl = 86400
        max_ttl = 31536000
        forwarded_values {
            query_string = true

            cookies {
                forward = "none"
            }
        }
        target_origin_id = aws_s3_bucket.deploy_bucket.id
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods = [ "HEAD", "GET" ]
        cached_methods = [ "HEAD", "GET" ]
    }
    enabled = true
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
}

// A record in route 53 to pass traffic from our domain to the cloudfront distribution
resource "aws_route53_record" "morleystuff_dns" {
    zone_id = "ZT0O09PTBTJOV"
    name = "morleystuff.com"
    type = "A"
    alias {
        zone_id = "Z2FDTNDATAQYW2"
        name = aws_cloudfront_distribution.morleystuff-cloudfront.domain_name
        evaluate_target_health = false
    }
}