#!/usr/bin/env bash

# Download the war file for the Jenkins version specified in
# ${jenkins_version} and start Jenkins server.

set -euo pipefail # http://redsymbol.net/articles/unofficial-bash-strict-mode
IFS=$'\n\t'

# Initialize variables
port=8081
jenkins_version="2.346.2"
debug=0

jpm_version="2.12.8"
plugins_file="plugins.txt"

tmp_dir="/tmp/${USER}/"
while [ $# -gt 0 ]
do
    case "$1" in
        "-p"|"--port" ) shift
                        port="$1";;
        "-v"|"--version" ) shift
                           jenkins_version="$1";;

        "-D"|"--debug" ) debug=1;;
    esac
    shift # expose next argument
done

jenkins_war_path="${tmp_dir}/jenkins.${jenkins_version}.war"

# https://community.jenkins.io/t/version-controlling-jenkins-config-help-defining-a-gitignore-that-minimizes-the-git-repo-size/3036
update_plugins () {
    jpm_repo_url="https://github.com/jenkinsci/plugin-installation-manager-tool"
    jenkins_plugins_dir="webroot/plugins/"

    jpm_jar_path="${tmp_dir}/jenkins-plugin-manager.${jpm_version}.jar"

    if [[ ! -f "${jpm_jar_path}" ]]
    then
        curl -RL "${jpm_repo_url}"/releases/download/"${jpm_version}"/jenkins-plugin-manager-"${jpm_version}".jar \
             --create-dirs -o "${jpm_jar_path}"
    fi

    echo "Updating ${jenkins_plugins_dir} .."
    java -jar "${jpm_jar_path}" \
         --war "${jenkins_war_path}" \
         --jenkins-version "${jenkins_version}" \
         --plugin-download-directory "${jenkins_plugins_dir}" \
         --plugin-file "${plugins_file}"
}

main () {
    if [[ ${debug} -eq 1 ]]
    then
        echo "Debug mode"
    fi

    if [[ ! -f "${jenkins_war_path}" ]]
    then
        curl -RL https://get.jenkins.io/war-stable/"${jenkins_version}"/jenkins.war \
             --create-dirs -o "${jenkins_war_path}"
    fi

    if [[ -f "${plugins_file}" ]]
    then
        update_plugins
    fi

    echo "Jenkins version:"
    java -jar "${jenkins_war_path}" --version

    echo "Starting server .."
    JENKINS_HOME="$(pwd)/webroot" java -jar "${jenkins_war_path}" --httpPort="${port}"
}

main
