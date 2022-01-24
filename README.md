# Bazel rules for python_black

Experimental Bazel rules to check and format your Python files with [black](https://github.com/psf/black).

Alternatively, consider using [bazel-linting-system](https://github.com/thundergolfer/bazel-linting-system).
The ergonomics of that project didn't feel quite right for me, but many people like it.

Features:

- Enable automatic validation of the format of your Python code
- Reformat your Python code using `black`

## Installation

1. From the release you wish to use:
   <https://github.com/caseyduquettesc/rules_python_black/releases>
   copy the WORKSPACE snippet into your `WORKSPACE` file.

2. Add `black` to your requirements file, you'll be supplying your own dependency.

3. Use the `py_black` macro to create the binary and formatting targets for `black`.
   In this example, we'll assume all `black`-related configuration will be in the
   `tools/black` project folder.

```starlark
# tools/black/BUILD.bazel

load("@py_deps//:requirements.bzl", "requirement")
load("@rules_python_black//python_black:defs.bzl", "py_black")

# To provide a custom configuration file (optional)
exports_files(["black.cfg"])

# Configure the black binary target and the formatting target.
# Generates the targets:
#   - black.bin
#   - black.format
py_black(
    # Optional name, defaults to "black"
    #name = "black",
    # Optional bazel command to use in the format command when a check fails
    #bazel_command = "bzl",
    # Optional message to print when a check fails
    #failure_message = None,
    # Required
    black_pypi_target = requirement("black"),
)
```

4. (Optional) If you have a custom configuration file you want to use, go ahead and place it in `tools/black/black.cfg`

5. (Optional) If you want to shorten the labels to `black` a tiny bit, you can create alias' in `tools/BUILD.bazel`

```starlark
alias(
    name = "black.bin",
    actual = "//tools/black:black.bin",
)

alias(
    name = "black.format",
    actual = "//tools/black:black.format",
)
```

6. Add the aspect to the `.bazelrc` file to enable failing the build on bad code formatting.
   Personally, I like to only enable this in CI because I find it a little annoying between commits.

```ini
# Enable black during build and test to force formatting on all code files
build:black --aspects="@rules_python_black//python_black:defs.bzl%black_aspect" --output_groups=+black_checks
build --@rules_python_black//python_black:black.exe=//tools/black:black.bin
# Optional, if you have your own config file
build --@rules_python_black//python_black:black.cfg=//tools/black:black.cfg
build --config=black
```

You can also check out the docs at [docs/rules.md](docs/rules.md).

## Usage

Assuming you followed all the installation steps and used `tools/black/BUILD.bazel` to define everything.

**Checking the code**

If you don't have the aspect enabled by default, like for instance, if you instead had `build:ci --config=black`
or something, and you wanted to know how you could manually run the check locally.

```commandline
bazel build --config=black <target|pattern>
```

**Formatting the code**

```commandline
bazel run //tools/black:black.format
```

If you followed the optional step 5 and created an alias in `tools/BUILD.bazel`, then you can use

```commandline
bazel run //tools:black.format
```

## Disclaimer

I rely on this myself and will accept issue reports and contributions, however this doesn't have automated tests and isn't
documented terribly well. I will maintain this, however the expectation is that
[bazel-linting-system](https://github.com/thundergolfer/bazel-linting-system) or something like it
will become the linting standard and at that
point, maybe these rules can be deprecated.

## Credits

- Initial version was a port of https://github.com/arrdem/source/blob/trunk/tools/black/black.bzl
- https://dev.to/davidb31/experimentations-on-bazel-python-3-linter-pytest-49oh
