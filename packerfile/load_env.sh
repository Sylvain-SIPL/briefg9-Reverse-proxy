#!/bin/bash

# load file .env
export $(grep -v '^#' .env | xargs)

# Launch build
packer build debianiso.pkr.hcl
packer build nginxiso.pkr.hcl


