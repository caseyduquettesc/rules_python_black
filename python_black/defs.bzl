"""Linting code format for Python using Aspects."""

load("@bazel_skylib//rules:write_file.bzl", "write_file")

# Hacked up from https://github.com/bazelbuild/rules_rust/blob/main/rust/private/clippy.bzl

def _black_aspect_impl(target, ctx):
    if hasattr(ctx.rule.attr, "srcs"):
        black = ctx.attr._black.files_to_run
        config = ctx.file._config

        files = []
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.extension == "py" and not f.path.startswith("external/"):
                    files.append(f)

        if files:
            report = ctx.actions.declare_file(ctx.label.name + ".black.report")
        else:
            return []

        args = ctx.actions.args()
        args.add_all([
            "--check",
            "--output-file",
            report,
            "--argsfile",
            "%s/%s/_black-arguments" % (ctx.workspace_name, ctx.attr._black.label.package),
        ])
        if config:
            args.add_all(["--config", config])
        for f in files:
            args.add(f)

        ctx.actions.run(
            executable = black,
            inputs = files,
            tools = [config] + ctx.attr._black.files.to_list(),
            arguments = [args],
            outputs = [report],
            mnemonic = "Black",
        )

        return [
            OutputGroupInfo(black_checks = depset([report])),
        ]

    return []

black_aspect = aspect(
    doc = """
The aspect causes the build to fail if the source is improperly formatted. This may not provide
the best experience while developing locally because you may not want to format your code until
you're ready to commit.

Place the following your `.bazelrc` to enable checking code format automatically. Set the labels
to your black config file (optional) and black binary. The black binary will be the label of your
`py_black` target + ".bin".

```ini
# Enable black during build and test to force formatting on all code files
build:black --aspects="@rules_python_black//python_black:defs.bzl%black_aspect" --output_groups=+black_checks
build --@rules_python_black//python_black:black.cfg=<label for black config>
build --@rules_python_black//python_black:black.exe=<label for black bin>
build --config=black
```
    """,
    implementation = _black_aspect_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_black": attr.label(default = Label("//python_black:black.exe")),
        "_config": attr.label(
            default = Label("//python_black:black.cfg"),
            executable = False,
            allow_single_file = True,
        ),
    },
)

def _black_rule_impl(ctx):
    ready_targets = [dep for dep in ctx.attr.deps if "black_checks" in dir(dep[OutputGroupInfo])]
    files = depset([], transitive = [dep[OutputGroupInfo].black_checks for dep in ready_targets])
    return [DefaultInfo(files = files)]

black = rule(
    implementation = _black_rule_impl,
    attrs = {
        "deps": attr.label_list(aspects = [black_aspect]),
    },
)

def py_black(name = "black", black_pypi_target = None, failure_message = None, bazel_command = "bazel"):
    """Defines the targets used to run black and format the code.

    ```starlark
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

    Args:
      name: Optional name to use for the generated targets.
      black_pypi_target: This should be the pypi dependency label for black, using the `requirement` function from `rules_python`.
      failure_message: Optional message to be shown when the check fails (in addition to the usual black output).
        By default, the message "Format files with: bazel run //<package>:black.format" will be shown. To disable
        this behavior, pass the empty string ("").
      bazel_command: Optional command to use in place of the word "bazel" in the default failure message.
    """
    if black_pypi_target == None:
        fail("'black_pypi_target' is a required argument and must be the label of the 'black' PyPi dependency")

    if bazel_command == None:
        bazel_command = "bazel"

    package_name = native.package_name()

    if failure_message == None:
        failure_message = "Format files with: %s run //%s:%s.format" % (bazel_command, package_name, name)

    # Pass args statefully so that when the aspect runs, the options are available
    write_file(
        name = name + ".bin-args",
        out = "_black-arguments",
        content = [
            "--failure-message=%s" % failure_message,
        ],
        visibility = [
            "//visibility:public",
        ],
    )

    native.py_binary(
        name = name + ".bin",
        srcs = [Label("//python_black:__main__.py")],
        main = Label("//python_black:__main__.py"),
        data = ["_black-arguments"],
        visibility = [
            "//visibility:public",
        ],
        deps = [
            black_pypi_target,
        ],
        python_version = "PY3",
    )

    # Update code format with black
    write_file(
        name = name + ".gen_format",
        out = "format.sh",
        content = [
            "#!/bin/sh",
            "set -e",
            "cd $BUILD_WORKSPACE_DIRECTORY",
            # TODO Find a hermetic, portable way to get cpu count. Alternatively, put up with 2 workers
            "logicalCpuCount=$([ $(uname) = 'Darwin' ] && sysctl -n hw.logicalcpu_max || lscpu -p | egrep -v '^#' | wc -l)",
            # Default excludes: /(\.direnv|\.eggs|\.git|\.hg|\.mypy_cache|\.nox|\.tox|\.venv|venv|\.svn|_build|buck-out|build|dist)/
            # Add the bazel output directories to exclusion
            "bazel-bin/%s/%s.bin --extend-exclude /bazel-.*/ --workers ${logicalCpuCount:-2} ." % (package_name, name),
        ],
        visibility = [
            "//visibility:public",
        ],
    )

    native.sh_binary(
        name = name + ".format",
        srcs = ["format.sh"],
        data = [":%s.bin" % name],
        visibility = [
            "//visibility:public",
        ],
    )
