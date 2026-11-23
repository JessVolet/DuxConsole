#!/usr/bin/env bash
set -euo pipefail

plugin_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT

cp -a -- "$plugin_root/preview/compat/." "$stage/"

for entry in core components screens services fixtures locales assets uiconfig.json iconsconfig.json inputconfig.json; do
    cp -a -- "$plugin_root/$entry" "$stage/"
done
cp -- "$plugin_root/MockPreview.qml" "$stage/shell.qml"
while IFS= read -r -d '' qml_file; do
    file=${qml_file##*/}
    printf '%s 1.0 %s\n' "${file%.qml}" "$file" >> "${qml_file%/*}/qmldir"
done < <(find "$stage/core" "$stage/components" "$stage/screens" "$stage/services" -name '*.qml' -print0)

printf 'Preview config: %s\n' "$stage/shell.qml"
qs -p "$stage" "$@"
