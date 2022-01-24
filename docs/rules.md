<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Linting code format for Python using Aspects.

<a id="#black"></a>

## black

<pre>
black(<a href="#black-name">name</a>, <a href="#black-deps">deps</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="black-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="black-deps"></a>deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#py_black"></a>

## py_black

<pre>
py_black(<a href="#py_black-name">name</a>, <a href="#py_black-black_pypi_target">black_pypi_target</a>, <a href="#py_black-failure_message">failure_message</a>, <a href="#py_black-bazel_command">bazel_command</a>)
</pre>

Defines the targets used to run black and format the code.

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


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="py_black-name"></a>name |  Optional name to use for the generated targets.   |  <code>"black"</code> |
| <a id="py_black-black_pypi_target"></a>black_pypi_target |  This should be the pypi dependency label for black, using the <code>requirement</code> function from <code>rules_python</code>.   |  <code>None</code> |
| <a id="py_black-failure_message"></a>failure_message |  Optional message to be shown when the check fails (in addition to the usual black output). By default, the message "Format files with: bazel run //&lt;package&gt;:black.format" will be shown. To disable this behavior, pass the empty string ("").   |  <code>None</code> |
| <a id="py_black-bazel_command"></a>bazel_command |  Optional command to use in place of the word "bazel" in the default failure message.   |  <code>"bazel"</code> |


<a id="#black_aspect"></a>

## black_aspect

<pre>
black_aspect(<a href="#black_aspect-name">name</a>)
</pre>


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
    

**ASPECT ATTRIBUTES**


| Name | Type |
| :------------- | :------------- |
| deps| String |


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="black_aspect-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |   |


