# Declare aws providers in APAC & EMEA
provider "aws" {
    profile = "default"
    alias   = "apac"
    region  = "ap-southeast-2"
}
provider "aws" {
    profile = "default"
    alias   = "emea"
    region  = "eu-central-1"
}

# Create VPC in APAC region for apps to deploy to
module "apac_network" {
    source = "./network"
    providers = {
        aws = aws.apac
    }
}

# Create VPC in EMEA region for apps to deploy to
module "emea_network" {
    source = "./network"
    providers = {
        aws = aws.emea
    }
}

module "valheim_server" {
    source = "./valheim"
    subnet_id = module.emea_network.subnet1_id
    providers = {
        aws = aws.emea
    }
}

module "morleystuff_site" {
    source = "./morleystuff-site"
    providers = {
        aws = aws.emea
    }
}