"""Shared implementation for PySpark hermetic rules."""

load("@rules_python//python:defs.bzl", "py_binary", "py_test")
load("@rules_java//java/common:java_common.bzl", "java_common")

def _pyspark_app_common_impl(ctx, internal_binary):
    """Common logic for setting up the hermetic PySpark environment."""
    py_toolchain = ctx.toolchains["@rules_python//python:toolchain_type"]
    py_runtime = py_toolchain.py3_runtime
    py_interpreter_path = py_runtime.interpreter.short_path

    if ctx.attr.java_runtime != None:
        java_runtime = ctx.attr.java_runtime[java_common.JavaRuntimeInfo]
    else:
        # Instead of just taking the 'default' from the toolchain,
        # ensure we are looking at the target's java_runtime.
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:toolchain_type"]
        
        # This field 'java' actually points to the TemplateVariableInfo/JavaRuntime
        # that respects the --java_runtime_version flag.
        java_runtime = java_toolchain.java.java_runtime

    wrapper = ctx.actions.declare_file(ctx.label.name + "_wrapper.sh")
    
    content = """#!/bin/bash
export JAVA_HOME="$PWD/{java_home}"
export PATH="$JAVA_HOME/bin:$PATH"

echo $JAVA_HOME

# Force Spark to use the hermetic Bazel interpreter
export PYSPARK_PYTHON="$PWD/{py_path}"
export PYSPARK_DRIVER_PYTHON="$PWD/{py_path}"

exec ./{internal_binary_path} "$@"
""".format(
        java_home = java_runtime.java_home_runfiles_path,
        py_path = py_interpreter_path,
        internal_binary_path = internal_binary.short_path,
    )
    
    ctx.actions.write(wrapper, content, is_executable = True)
    
    return [DefaultInfo(
        executable = wrapper,
        runfiles = ctx.runfiles(files = [internal_binary])
            .merge(ctx.attr.binary[DefaultInfo].default_runfiles if hasattr(ctx.attr, "binary") else ctx.attr.test_binary[DefaultInfo].default_runfiles)
            .merge(ctx.runfiles(transitive_files = java_runtime.files))
            .merge(ctx.runfiles(transitive_files = py_runtime.files))
    )]

def _pyspark_binary_runner_impl(ctx):
    return _pyspark_app_common_impl(ctx, ctx.executable.binary)

_pyspark_binary_runner = rule(
    implementation = _pyspark_binary_runner_impl,
    executable = True,
    attrs = {
        "binary": attr.label(executable = True, cfg = "target", mandatory = True),
        # Optional attribute: if not set, we use toolchain
        "java_runtime": attr.label(providers = [java_common.JavaRuntimeInfo]),
    },
    toolchains = [
        "@rules_python//python:toolchain_type",
        "@bazel_tools//tools/jdk:toolchain_type",
    ],
)

def pyspark_binary(name, java_runtime = None, **kwargs):
    """Defines a PySpark binary with proper Java runtime configuration."""
    raw_bin_name = "_" + name + "_raw_bin"
    
    main = kwargs.pop("main", name + ".py")
    tags = kwargs.pop("tags", [])
    visibility = kwargs.pop("visibility", None)

    py_binary(
        name = raw_bin_name,
        main = main,
        visibility = ["//visibility:private"],
        tags = tags + ["manual"],
        **kwargs,
    )

    _pyspark_binary_runner(
        name = name,
        binary = ":" + raw_bin_name,
        java_runtime = java_runtime,
        visibility = visibility,
        tags = tags,
    )

def _pyspark_test_runner_impl(ctx):
    return _pyspark_app_common_impl(ctx, ctx.executable.test_binary)

_pyspark_test_runner_test = rule(
    implementation = _pyspark_test_runner_impl,
    executable = True,
    test = True,
    attrs = {
        "test_binary": attr.label(executable = True, cfg = "target", mandatory = True),
        # Optional attribute: if not set, we use toolchain
        "java_runtime": attr.label(providers = [java_common.JavaRuntimeInfo]),
    },
    toolchains = [
        "@rules_python//python:toolchain_type",
        "@bazel_tools//tools/jdk:toolchain_type",
    ],
)

def pyspark_test(name, java_runtime = None, pytest_args = None, **kwargs):
    """Defines a PySpark test with proper Java runtime configuration.

    Args:
        name: The name of the test target.
        java_runtime: The Java runtime to use for the test. Defaults to remotejdk_17.
        pytest_args: Additional arguments to pass to pytest.
        **kwargs: Additional arguments to pass to py_test.
    """
    if pytest_args == None:
        pytest_args = ["--ignore=external", "-p", "no:cacheprovider"]

    raw_test_name = "_" + name + "_raw_test"

    if "main" in kwargs:
        fail("if you need to specify main, use py_test directly")

    deps = kwargs.pop("deps", []) + ["//:pytest_helper"]
    srcs = kwargs.pop("deps", []) + ["//:pytest_helper.py"]
    args = kwargs.pop("args", [native.package_name()]) + pytest_args
    tags = kwargs.pop("tags", [])

    py_test(
        name = raw_test_name,
        srcs = srcs,
        main = "//:pytest_helper.py",
        args = args,
        deps = deps,
        imports = kwargs.pop("imports", []) + ["."],
        tags = ["manual", "notap"],
        visibility = ["//visibility:private"],
        **kwargs,
    )

    _pyspark_test_runner_test(
        name = name,
        test_binary = ":" + raw_test_name,
        java_runtime = java_runtime,
        args = args,
        visibility = kwargs.get("visibility"),
        tags = tags,
        size = kwargs.get("size", "medium"),
        timeout = kwargs.get("timeout"),
        flaky = kwargs.get("flaky"),
    )