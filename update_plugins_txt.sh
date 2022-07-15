#!/usr/bin/env bash

# Update a text file containing the installed plugins in
# webroot/plugins/ and their versions.

set -euo pipefail # http://redsymbol.net/articles/unofficial-bash-strict-mode
IFS=$'\n\t'

jpm_repo_url="https://github.com/jenkinsci/plugin-installation-manager-tool"
jenkins_plugins_dir="webroot/plugins/"
plugins_file="plugins.txt"

# Initialize variables
jpm_version="2.12.8"
debug=0

tmp_dir="/tmp/${USER}/"
while [ $# -gt 0 ]
do
    case "$1" in
        "-v"|"--version" ) shift
                           jpm_version="$1";;

        "-D"|"--debug" ) debug=1;;
    esac
    shift # expose next argument
done

main () {
    if [[ ${debug} -eq 1 ]]
    then
        echo "Debug mode"
    fi

    jpm_jar_path="${tmp_dir}/jenkins-plugin-manager.${jpm_version}.jar"

    if [[ ! -f "${jpm_jar_path}" ]]
    then
        curl -RL "${jpm_repo_url}"/releases/download/"${jpm_version}"/jenkins-plugin-manager-"${jpm_version}".jar \
             --create-dirs -o "${jpm_jar_path}"
    fi

    echo "Jenkins Plugins Manager version:"
    java -jar "${jpm_jar_path}" --version

    echo "Updating plugins.txt .."
    java -jar "${jpm_jar_path}" \
         --plugin-download-directory "${jenkins_plugins_dir}" \
         --output TXT \
         --list > "${plugins_file}"
}

main
