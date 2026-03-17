#!/usr/bin/env bash
# Make cbz from downloaded mangas
# shellcheck disable=SC2016
# shellcheck source=/dev/null

set -e

_usage() {
    printf "%b" "
The script will convert directories containing images to cbz archives.\n

Usage: ${0##*/} manga_dir [options.. \n
  -h | --help - Display usage instructions.\n"
    exit
}

_short_help() {
    printf "No valid arguments provided, use -h/--help flag to see usage.\n"
    exit
}

_setup_arguments() {
    unset FOLDER

    CONFIG="${HOME}/.mangadl-bash.conf"
    [[ -f ${CONFIG} ]] && . "${CONFIG}"

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -h | --help) _usage ;;
            '') shorthelp ;;
            *)
                # Check if user meant it to be a flag
                if [[ ${1} = -* ]]; then
                    printf '%s: %s: Unknown option\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${1}" "${0##*/}" && exit 1
                else
                    # If no "-" is detected in 1st arg, it adds to input
                    INPUT_ARRAY+=("${1}")
                fi
                ;;
        esac
        shift
    done

    _check_debug

    [[ -z ${INPUT_ARRAY[*]} ]] && _short_help

    return 0
}

###################################################
# Process all the values in "${INPUT_ARRAY[@]}"
# Arguments: None
# Result: Do whatever set by flags
###################################################
_process_arguments() {
    for input in "${INPUT_ARRAY[@]}"; do
        _make_cbz "${input}"
    done
}

_make_cbz() {
    local input="$1"

    pushd .
    cd "${input}"
    local manga=$(basename "${input}")
    local converted=0
    if [ -d converted ]; then
        _print_center "justify" "Using converted files" "-"
        converted=1
        cd converted
    fi

    for episode in *; do
        { [ ! -d "${episode}" ] || [ "${episode}" = "converted" ] ; } && continue

        local filename="${manga} ${episode}.cbz"
        _print_center "justify" "Creating \"${filename}\"..." "-"

        cd "${episode}"
        local out="../../${filename}"
        [ "$converted" -eq 1 ] && out="../$out"

        rm -f "${out}"
        zip -q -0 "${out}" *.jpeg *.jpg *.png *.webp
        cd ..
    done

    popd >/dev/null
}

main() {
    [[ $# = 0 ]] && _short_help

    [[ -z ${SELF_SOURCE} ]] && {
        UTILS_FOLDER="${UTILS_FOLDER:-${INSTALL_PATH:-./utils}}"
        { . "${UTILS_FOLDER}"/common-utils.bash && . "${UTILS_FOLDER}"/scraper-utils.bash; } || { printf "Error: Unable to source util files.\n" && exit 1; }
    }

    _check_bash_version && { set -o errexit -o noclobber -o pipefail; shopt -s nullglob; }

    _setup_arguments "${@}"

    trap 'abnormal_exit="1"; exit' INT TERM
    trap '' TSTP # ignore ctrl + z

    START="$(printf "%(%s)T\\n" "-1")"
    _process_arguments
    END="$(printf "%(%s)T\\n" "-1")"
    DIFF="$((END - START))"

    "${QUIET:-_print_center}" "normal" " Time Elapsed: ""$((DIFF / 60))"" minute(s) and ""$((DIFF % 60))"" seconds " "="
}

{ [[ -z ${SOURCED_MANGADL:-} ]] && main "${@}"; } || :
