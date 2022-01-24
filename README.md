# Template for Bazel rules

Copy this template to create a Bazel ruleset.

Features:

- follows the official style guide at https://docs.bazel.build/versions/main/skylark/deploying.html
- includes Bazel formatting as a pre-commit hook (using [buildifier])
- includes stardoc API documentation generator
- includes typical toolchain setup
- CI configured with GitHub Actions
- Release on GitHub Actions when pushing a tag

See https://docs.bazel.build/versions/main/skylark/deploying.html#readme

[buildifier]: https://github.com/bazelbuild/buildtools/tree/master/buildifier#readme

Ready to get started? Copy this repo, then

1. search for "rules_python_black" and replace with the name you'll use for your workspace
1. search for "caseyduquettesc" and replace with GitHub org
1. search for "python_black" and replace with the language/tool your rules are for
1. rename directory "python_black" similarly
1. run `pre-commit install` to get lints (see CONTRIBUTING.md)
1. if you don't need to fetch platform-dependent tools, then remove anything toolchain-related.
1. update the `actions/cache@v2` bazel cache key in [.github/workflows/ci.yaml](.github/workflows/ci.yaml) and [.github/workflows/release.yml](.github/workflows/release.yml) to be a hash of your source files.
1. delete this section of the README (everything up to the SNIP).

---- SNIP ----

# Bazel rules for python_black

## Installation

From the release you wish to use:
<https://github.com/caseyduquettesc/rules_python_black/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.
