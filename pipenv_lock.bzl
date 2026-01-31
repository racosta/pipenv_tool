"""Define a rule for `pipenv_lock` to generate a Pipfile.lock from a requirements.txt file."""

def _pipenv_lock_impl(ctx):
    """Implementation of the pipenv_lock rule."""

    # Declare the output Pipfile.lock
    pipfile_lock = ctx.actions.declare_file("Pipfile.lock")

    # Create a minimal Pipfile
    pipfile = ctx.actions.declare_file("Pipfile")
    ctx.actions.write(
        output = pipfile,
        content = """[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]

[dev-packages]

[requires]
python_version = "3"
""",
    )

    requirements_file = ctx.file.requirements

    ctx.actions.run(
        outputs = [pipfile_lock],
        inputs = [requirements_file, pipfile],
        tools = [ctx.attr._pipenv[DefaultInfo].files_to_run],
        executable = ctx.executable._pipenv,
        arguments = [
            "install",
            "-r",
            requirements_file.path,
        ],
        env = {
            "PIPENV_PIPFILE": pipfile.path,
            "PIPENV_VENV_IN_PROJECT": "1",
        },
        mnemonic = "PipenvLock",
        progress_message = "Generating Pipfile.lock from %s" % requirements_file.short_path,
    )

    return [DefaultInfo(files = depset([pipfile_lock]))]

pipenv_lock = rule(
    implementation = _pipenv_lock_impl,
    attrs = {
        "requirements": attr.label(
            allow_single_file = [".txt"],
            mandatory = True,
            doc = "The requirements.txt file to convert to Pipfile.lock",
        ),
        "_pipenv": attr.label(
            default = Label("//:pipenv"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Generates a Pipfile.lock file from a requirements.txt file.",
)
