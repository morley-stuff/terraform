provider "aws" {
    profile = "default"
    region  = "ap-southeast-2"
}

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

resource "aws_cloudfront_distribution" "morleystuff-cloudfront" {
    origin {
        s3_origin_config {
          origin_access_identity = ""
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

resource "aws_codepipeline" "codepipeline" {
    name = "morleystuff-site-pipeline"
    role_arn = aws_iam_role.codepipeline_role.arn

    artifact_store {
        location = aws_s3_bucket.codepipeline_bucket.bucket
        type = "S3"
    }

    stage {
        name = "Source"

        action {
            name = "SourceAction"
            category = "Source"
            owner = "ThirdParty"
            provider = "GitHub"
            version = "1"
            output_artifacts = [ "source_output" ]
            configuration = {
              "Owner" = var.GithubOwner,
              "Repo" = var.GithubRepo,
              "Branch" = "master",
              "OAuthToken" = var.GithubOAuthToken
            }
        }
    }

    stage {
        name = "Build"

        action {
            name = "BuildAction"
            category = "Build"
            owner = "AWS"
            version = "1"
            provider = "CodeBuild"
            input_artifacts = [ "source_output" ]
            output_artifacts = [ "build_output" ]
            configuration = {
              "ProjectName" = aws_codebuild_project.codebuild_project.name
            }
        }
    }
}

resource "aws_iam_role" "codebuild_role" {
    name = "codebuild-role"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "deploy_bucket" {
    website {
      index_document = "index.html"
      error_document = "index.html"
    }
}

resource "aws_codebuild_project" "codebuild_project" {
    name = "Morleystuff-Site-CodeBuild"
    service_role = aws_iam_role.codebuild_role.arn

    artifacts {
      type = "CODEPIPELINE"
      name = "MorleyStuff-Site-Pipeline"
    }

    environment {
        compute_type = "BUILD_GENERAL1_SMALL"
        type = "LINUX_CONTAINER"
        image = "aws/codebuild/standard:4.0"
    }

    source {
        type = "CODEPIPELINE"
        buildspec = <<EOF
{
    "version": "0.2",
    "phases": {
        "install": {
            "runtime-versions": {
                "nodejs": "10"
            }
        },
        "pre_build": {
            "commands": [
                "echo Installing source dependencies...",
                "npm install"
            ]
        },
        "build": {
            "commands": [
                "echo Build started on `date`",
                "npm run build"
            ]
        },
        "post_build": {
            "commands": [
                "aws s3 cp --recursive --acl public-read ./build s3://${aws_s3_bucket.deploy_bucket.id}/",
                "aws s3 cp --acl public-read --cache-control='max-age=0, no-cache, no-store, must-revalidate' ./build/index.html s3://${aws_s3_bucket.deploy_bucket.id}/",
            ]
        }
    },
    "artifacts": {
        "files": [
            "**/*"
        ],
        "base-directory": "build"
    }
}
EOF
    }

}

resource "aws_iam_role_policy" "codebuild_policy" {
    role = aws_iam_role.codebuild_role.name

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketVersioning",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.codepipeline_bucket.arn}",
                "${aws_s3_bucket.codepipeline_bucket.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketVersioning",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "${aws_s3_bucket.deploy_bucket.arn}",
                "${aws_s3_bucket.deploy_bucket.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "*"
        }
    ]

}
POLICY
}

resource "aws_s3_bucket" "codepipeline_bucket" {
}

resource "aws_iam_role" "codepipeline_role" {
    name = "codepipeline_role"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
    name = "codepipeline_policy"
    role = aws_iam_role.codepipeline_role.id

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketVersioning",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.codepipeline_bucket.arn}",
                "${aws_s3_bucket.codepipeline_bucket.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}