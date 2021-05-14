// Bucket for storing build artifacts
resource "aws_s3_bucket" "codepipeline_bucket" {}

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

// Pipeline connecting Git source to Codebuild project
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