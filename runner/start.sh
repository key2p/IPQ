#!/bin/bash

[ -e /dev/shm/start.sh ] && bash /dev/shm/start.sh && exit $?

if [[ ! -z $git_proxy ]]; then
    echo "set git http proxy ${git_proxy}."
    git config --global http.proxy $git_proxy || true
    sudo -E git config --global http.proxy "$git_proxy" || true
    sudo -E git config --global https.proxy "$git_proxy" || true
fi

if [[ ! -z $apt_proxy ]]; then
    echo "set apt http proxy ${apt_proxy}."
    (echo -e "Acquire::http::Proxy \"${apt_proxy}\";\nAcquire::https::Proxy \"${apt_proxy}\";" | sudo -E tee /etc/apt/apt.conf.d/01proxy) || true
else    
    sudo rm /etc/apt/apt.conf.d/01proxy || true
fi

if [[ -z $RUNNER_TOKEN && -z $GITHUB_ACCESS_TOKEN ]]; then
    echo "Error : You need to set RUNNER_TOKEN (or GITHUB_ACCESS_TOKEN) environment variable."
    exit 1
fi

if [[ -z $RUNNER_REPOSITORY_URL && -z $RUNNER_ORGANIZATION_URL ]]; then
    echo "Error : You need to set the RUNNER_REPOSITORY_URL (or RUNNER_ORGANIZATION_URL) environment variable."
    exit 1
fi

if [[ ! -z $RUNNER_ORGANIZATION_URL ]]; then
    SCOPE="orgs"
    RUNNER_URL="${RUNNER_ORGANIZATION_URL}"
else
    SCOPE="repos"
    RUNNER_URL="${RUNNER_REPOSITORY_URL}"
fi

if [[ -n $GITHUB_ACCESS_TOKEN ]]; then
    echo "Exchanging the GitHub Access Token with a Runner Token (scope: ${SCOPE})..."

    _PROTO="$(echo "${RUNNER_URL}" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    _URL="$(echo "${RUNNER_URL/${_PROTO}/}")"
    _PATH="$(echo "${_URL}" | grep / | cut -d/ -f2-)"

    echo "_PATH: $_PATH"

    RUNNER_TOKEN="$(curl -XPOST -fsSL \
        -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/${SCOPE}/${_PATH}/actions/runners/registration-token" \
        | jq -r '.token')"
fi

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token $RUNNER_TOKEN
}

cd /home/docker/actions-runner

#export RUNNER_ALLOW_RUNASROOT=1
./config.sh --url $RUNNER_URL --token $RUNNER_TOKEN

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh --once & wait $!

cleanup
exit $err