#!/usr/bin/env bash
set -euo pipefail

plugin_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_entry=MockPreview.qml
if [[ "${1:-}" == --reuse ]]; then
    shell_entry=ReusePreview.qml
    shift
fi
if [[ "$shell_entry" == MockPreview.qml && -n "${DUX_PREVIEW_CONTROLLER:-}" ]]; then
    if [[ ! "$DUX_PREVIEW_CONTROLLER" =~ ^/dev/input/event[0-9]+$ ]] ||
       [[ ! -c "$DUX_PREVIEW_CONTROLLER" || ! -r "$DUX_PREVIEW_CONTROLLER" ]]; then
        printf 'Preview controller must be a readable /dev/input/eventN character device.\n' >&2
        exit 1
    fi
    controller_sysfs="/sys/class/input/${DUX_PREVIEW_CONTROLLER##*/}/device"
    if [[ ! -d "$controller_sysfs" ]] || ! compgen -G "$controller_sysfs/js[0-9]*" >/dev/null; then
        printf 'Preview controller must expose a Linux joystick interface.\n' >&2
        exit 1
    fi
    if ! command -v evtest >/dev/null || ! command -v stdbuf >/dev/null; then
        printf 'The preview controller adapter requires evtest and stdbuf.\n' >&2
        exit 1
    fi
fi
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT

cp -a -- "$plugin_root/preview/compat/." "$stage/"

for entry in core components screens services fixtures locales assets uiconfig.json iconsconfig.json inputconfig.json; do
    cp -a -- "$plugin_root/$entry" "$stage/"
done
cp -- "$plugin_root/$shell_entry" "$stage/shell.qml"
while IFS= read -r -d '' qml_file; do
    file=${qml_file##*/}
    printf '%s 1.0 %s\n' "${file%.qml}" "$file" >> "${qml_file%/*}/qmldir"
done < <(find "$stage/core" "$stage/components" "$stage/screens" "$stage/services" -name '*.qml' -print0)

printf 'Preview config: %s\n' "$stage/shell.qml"
qs -p "$stage" "$@"
