#!/bin/bash

# Clone harbor ARM64 code
# git clone https://github.com/amy5200/build-harbor-arm64.git

GIT_BRANCH="v2.11.0"
DOCKER_CLI_EXPERIMENTAL="enabled"
ARCH="arm64"
DOCKER_DEFAULT_PLATFORM="linux/arm64"

# Install Node.js yarn
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
dnf install -y git nodejs rsync
npm install -g npm@latest
npm install --global yarn

# Replace harbor image tag
sed -i "s#dev-arm#${GIT_BRANCH}-aarch64#g" Makefile

# Download harbor source code
git clone --branch ${GIT_BRANCH} https://github.com/goharbor/harbor.git src/github.com/goharbor/harbor
cp -f ./harbor/Makefile src/github.com/goharbor/harbor/
cp -f ./harbor/make/photon/Makefile src/github.com/goharbor/harbor/make/photon/
cp -f ./harbor/src/portal/src/app/shared/components/about-dialog/about-dialog.component.html src/github.com/goharbor/harbor/src/portal/src/app/shared/components/about-dialog/

# compile redis
make compile_redis

# Prepare to build arm architecture image data:
make prepare_arm_data

# Replace build arm image parameters：
make pre_update

# Compile harbor components:
make compile COMPILETAG=compile_golangimage

# Build harbor arm image:
make build GOBUILDTAGS="include_oss include_gcs" BUILDBIN=true TRIVYFLAG=true GEN_TLS=true PULL_BASE_FROM_DOCKERHUB=false
