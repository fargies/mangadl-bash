#!/usr/bin/env bash
# Functions related to mangasorigines
# shellcheck disable=SC2016

_search_manga_mangasorigines() {
    declare input="${1// /+}" num_of_search="${2}"

    SEARCH_HTML=$(curl -# --compressed -H "User-Agent: ${USER_AGENT}" "https://mangas-origines.fr/?post_type=wp-manga&s="$(_url_encode "${input}" +))
    _clear_line 1

    [[ ${SEARCH_HTML} = *"No Manga Series."* ]] && return 1

    SEARCH_HTML="$(grep --no-group-separator "row c-tabs-item__content" -A 8 ${num_of_search:+-m ${num_of_search}} <<< "${SEARCH_HTML}")"

    mapfile -t names <<< "$(grep -oP '(?<=title=")[^"]*(?=")' <<< "${SEARCH_HTML}")"
    mapfile -t urls <<< "$(grep -oP '(?<=href=")[^"]*(?=")' <<< "${SEARCH_HTML}")"

    i=1
    while read -r -u 4 name && read -r -u 7 url; do
        num="$((i++))"
        OPTION_NAMES+=("${num}. ${name}
   URL: ${url}")
    done 4<<< "$(printf "%s\n" "${names[@]}")" 7<<< "$(printf "%s\n" "${urls[@]}")"

    TOTAL_SEARCHES="${#names[@]}"
    export TOTAL_SEARCHES OPTION_NAMES
}

_set_manga_variables_mangasorigines() {
    declare option="${1}"

    SLUG="$(_basename "${urls[$((option - 1))]}")"
    NAME="${names[$((option - 1))]}"

    export SLUG NAME
}

_fetch_manga_details_mangasorigines() {
    declare slug HTML && unset VOLUMES
    slug="$(_basename "${1:-${SLUG}}")"

    HTML="$(curl -# --compressed -H "User-Agent: ${USER_AGENT}" -H "Content-Length: 0" -X POST -L "https://mangas-origines.fr/oeuvre/${slug}/ajax/chapters/?t=1" -w "\n%{http_code}\n")"
    _clear_line 1

    [[ ${HTML} = *"The page you were looking for doesn"* ]] && return 1

    ! [[ ${HTML} = *"Volume Not Available"* ]] && export VOLUMES="true"
    mapfile -t PAGES <<< $(grep -oP "(?<=href=\")[^\"]*${slug}/chapitre[^\"]*(?=\")" <<< "${HTML}" | sed -e 's#^.*chapitre-##' -e 's#/$##')

    mapfile -t PAGES <<< "$(_reverse "${PAGES[@]}")"

    export PAGES REFERER="mangas-origines.fr"
}

# download to create _chapter file
_download_chapter_mangasorigines() {
    curl -H "User-Agent: ${USER_AGENT}" -s "https://mangas-origines.fr/oeuvre/${SLUG}/chapitre-${page}/" -w "\n%{http_code}\n"
}

# download to create _images file
_count_images_mangasorigines() {
    TOTAL_IMAGES="$(: "$(for page in "${PAGES[@]}"; do
        {
            grep -Po "((http|https):)?//[^\"]*(jpg|jpeg|png|webp)(?=\")" "${page}/${page}"_chapter | grep "/WP-manga/" | sed 's#^//#https://#' >| "${page}/${page}"_images
            _count < "${page}/${page}"_images
        } &
    done)" && printf "%s\n" "$((${_//$'\n'/ + }))")"
    export TOTAL_IMAGES
}
