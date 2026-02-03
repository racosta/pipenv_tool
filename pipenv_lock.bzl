"""Define a rule for `pipenv_lock` to generate a Pipfile.lock from a requirements.txt file."""

def _pipenv_lock_impl(ctx):
    """Implementation of the pipenv_lock rule."""

    # Declare the output Pipfile.lock
    pipfile_lock = ctx.actions.declare_file("pipenv_env/Pipfile.lock")

    requirements_file = ctx.file.requirements

    ctx.actions.run_shell(
        outputs = [pipfile_lock],
        inputs = [requirements_file],
        tools = [ctx.executable._pipenv],
        command = """
exec_root=$(pwd)
cd $(dirname {pipfile_lock})
PIPENV_VENV_IN_PROJECT=1 $exec_root/{pipenv} --python 3.11 install -r $exec_root/{reqs}
""".format(
            pipfile_lock = pipfile_lock.path,
            pipenv = ctx.executable._pipenv.path,
            reqs = requirements_file.path,
        ),
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
