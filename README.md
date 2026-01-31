# Using `pipenv` as a Tool in a Bazel Rule

This is attempting to provide a minimal example that demonstrates the difference
in behavior for [`rules_python`](https://github.com/bazel-contrib/rules_python)
in versions 1.7.0+.

## `devenv`

This repository uses [`devenv`](https://devenv.sh/) to manage the developer environment.
If you have `devenv` installed and ready you can start the shell as easily as
`devenv shell` when at the root of this repository.

## Demonstrate the Issue

With the current settings (using version `1.8.3` of `rules_python`) there is a
failure when running `bazel build //:pipfile_lock`.

If I edit the `MODULE.bazel` to use version `1.6.3` (including the
`single_version_override`), then that same command succeeds.
