#!/bin/bash
# bump version in pyproject.toml

set -e

>&2 echo "Installing to .git/hooks/pre-commit ..."
fullpath=$(readlink -f "$0")
rootdir=$(dirname "$fullpath")
ln -sf "$fullpath" "$rootdir/.git/hooks/pre-commit"

# bump and print version
version=$(python -c "import wifipem; print(wifipem.__version__)")
poetry version "$version" 1>&2
echo "$version"
