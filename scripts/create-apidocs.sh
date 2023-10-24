#!/bin/bash
shopt -s nullglob
shopt -s nocaseglob

echo ""
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "Create APIdocs v0.1"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo ""

# Replace the -input and -output options with -i and -o respectively, because getopts can't handle long args.
for ARGS in "$@"; do
shift
        case "$ARGS" in
                "--input") set -- "$@" "-i" ;;
                "--output") set -- "$@" "-o" ;;
                *) set -- "$@" "$ARGS"
        esac
done

# Map options to variables.
while getopts 'i:o:' flag; do
        case "${flag}" in
                i) input_dir=${OPTARG} ;;
                o) output_dir=${OPTARG} ;;
        esac
done

current_dir="$(pwd -P)"
script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Missing parameters
if [ -z "${input_dir}" ] || [ -z "${output_dir}" ]; then
    echo "Use $(basename $0) --input <input_dir> --output <output_dir> to create APIdocs."
    echo ""
    exit 1
fi

# Check if input directory exists
if [ ! -d "${input_dir}" ]; then
    pwd
    echo "Inputdir ${input_dir} does not exist."
    echo ""
    exit 1
else
    input_dir="$( cd -- "${input_dir}" >/dev/null 2>&1 ; pwd -P )"
    echo "Input directory to scan for OpenAPI-specs: ${input_dir}"
fi

# Check if output directory exists. If not, create it
if [ ! -d "${output_dir}" ]; then
    echo "Directory does not exist. Create it..."
    mkdir "${output_dir}"
    if [ $? -ne 0 ]; then
        echo "Cannot create directory. Check directory name or access rights"
        exit 1
    fi
fi
output_dir="$( cd -- "${output_dir}" >/dev/null 2>&1 ; pwd -P )"
echo "Output directory to write the generated API-docs: ${output_dir}"
echo ""

# Switch to script directory to be able to use the locally installed NPM-package
cd "${script_dir}"
index_file="${output_dir}/index.html"

echo "<html><head><title>Cytometa APIdocs</title></head><body>" > ${index_file}
echo "<h1>Cytometa APIdocs</h1>" >> ${index_file}

# Walk through files and create APIdocs
for yaml_file in $(ls -1 ${input_dir}/*.{yml,yaml});
do
    file_name="${yaml_file##*/}"                         # Strip longest match of */ from start
    dir="${yaml_file:0:${#yaml_file} - ${#file_name}}"   # Substring from 0 thru pos of filename
    base="${file_name%.[^.]*}"                           # Strip shortest match of . plus at least one non-dot char from end
    ext="${file_name:${#base} + 1}"                      # Substring from len of base thru end
    if [[ -z "$base" && -n "$ext" ]]; then               # If we have an extension and no base, it's really the base
        base=".$ext"
        ext=""
    fi

    html_file="${output_dir}/${base}.html"
    #echo "Processing ${yaml_file}..."
    npx redoc-cli bundle ${yaml_file} -o ${html_file} --yes

    html_link="<a href=\"${base}.html\">${base}</a><br/>"
    echo "$html_link" >> ${index_file}

done

echo "</body></html>" >> ${index_file}