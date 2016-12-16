#!/bin/bash

[[ DEBUG -gt 0 ]] && set -x

usage () {
    printf "Inject content into file.\n"
    printf "${0##*/}\n"
    printf "\t-c CONTENT\n"
    printf "\t-f FILE\n"
    printf "\t-p <begin|end|after|before>\n"
    printf "\t[-a REGEX]\n"
    printf "\t[-b REGEX]\n"
    printf "\t[-m MARK_BEGIN]\n"
    printf "\t[-n MARK_END]\n"
    printf "\t[-x REGEX_MARK_BEGIN]\n"
    printf "\t[-y REGEX_MARK_END]\n"
    printf "\t[-h]\n"

    printf "OPTIONS\n"
    printf "\t-c CONTENT\n\n"
    printf "\tContent to inject.\n\n"

    printf "\t-f FILE\n"
    printf "\tFile to inject to.\n\n"

    printf "\t-p <begin|end|after|before>\n"
    printf "\tWhere to inject in the FILE.\n\n"

    printf "\t[-a REGEX]\n"
    printf "\tUse together with '-p after'.\n\n"

    printf "\t[-b REGEX]\n"
    printf "\tUse together with '-p before'.\n\n"

    printf "\t[-m MARK_BEGIN]\n"
    printf "\tUse together with -n.\n"
    printf "\tWith begin and end mark, injection can be run repeatly and safety.\n\n"

    printf "\t[-n MARK_END]\n"
    printf "\tUse together with -m.\n"
    printf "\tWith begin and end mark, injection can be run repeatly and safety.\n\n"

    printf "\t[-x REGEX_MARK_BEGIN]\n"
    printf "\tUse together with -y.\n"
    printf "\tWith begin and end mark, injection can be run repeatly and safety.\n\n"

    printf "\t[-y REGEX_MARK_END]\n"
    printf "\tUse together with -x.\n"
    printf "\tWith begin and end mark, injection can be run repeatly and safety.\n\n"

    printf "\t[-h]\n"
    exit 255
}

while getopts c:f:p:a:b:m:n:x:y:h opt; do
    case $opt in
        c)
            content=$OPTARG
            ;;
        f)
            file=$OPTARG
            ;;
        p)
            # begin, end, after, before
            position=$OPTARG
            ;;
        a)
            regex_after=$OPTARG
            ;;
        b)
            regex_before=$OPTARG
            ;;
        m)
            mark_begin=$OPTARG
            ;;
        n)
            mark_end=$OPTARG
            ;;
        x)
            regex_mark_begin=$OPTARG
            ;;
        y)
            regex_mark_end=$OPTARG
            ;;
        h|*)
            usage
            ;;
    esac
done

clean_exit () {
    rm -f "${tmp_file:?}"
    rm -f "${tmp_inj_file:?}"
    exit $1
}

# Backup
bak_file="${file:?}-$(date '+%Y%m%d%H%M%S')" || exit
/bin/cp -a "${file:?}" "${bak_file:?}" || exit

# Temporary file
tmp_file=/tmp/${0##*/}-${file##*/}-$$
tmp_inj_file=/tmp/${0##*/}-$$

/bin/cp -a "${file:?}" "${tmp_file:?}" || exit
if [[ -n $mark_begin && -n $mark_end ]]; then
    cat > "${tmp_inj_file:?}" << EOF || clean_exit $?
${mark_begin:?}
${content:?}
${mark_end:?}
EOF
else
    cat > "${tmp_inj_file:?}" << EOF || clean_exit $?
${content:?}
EOF
fi

# Remove early injection if exists
if [[ -n $regex_mark_begin && -n $regex_mark_end ]]; then
    sed -i -r "/${regex_mark_begin:?}/,/${regex_mark_end:?}/d" "${tmp_file:?}" || clean_exit $?
fi

# Injecting
case ${position:?} in
    begin)
        sed -i "1{
h
r ${tmp_inj_file:?}
g
N
}" "${tmp_file:?}" || clean_exit $?
        ;;
    end)
        sed -i "$ r ${tmp_inj_file:?}" "${tmp_file:?}" || clean_exit $?
        ;;
    after)
        sed -i -r "/${regex_after:?}/ r ${tmp_inj_file:?}" "${tmp_file:?}" || clean_exit $?
        ;;
    before)
        sed -i -r "/${regex_before:?}/{
h
r ${tmp_inj_file:?}
g
N
}" "${tmp_file:?}" || clean_exit $?
        ;;
    *)
        clean_exit 255
        ;;
esac

cp -a "${tmp_file:?}" "${file:?}"

clean_exit $?
