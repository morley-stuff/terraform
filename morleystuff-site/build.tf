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

// Codebuild project describing build & deployment for site
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