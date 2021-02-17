
// Bucket for storing build artifacts
resource "aws_s3_bucket" "codepipeline_bucket" {}

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







