#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
PREFIX="rules_python_black-${TAG:1}"
SHA=$(git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip | shasum -a 256 | awk '{print $1}')

cat << EOF
WORKSPACE snippet:
\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_python_black",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/caseyduquettesc/rules_python_black/archive/refs/tags/${TAG}.tar.gz",
)

# Fetches the rules_python_black dependencies.
# If you want to have a different version of some dependency,
# you should fetch it *before* calling this.
# Alternatively, you can skip calling this function, so long as you've
# already fetched all the dependencies.
load("@rules_python_black//python_black:repositories.bzl", "rules_python_black_dependencies")
rules_python_black_dependencies()

\`\`\`
EOF
