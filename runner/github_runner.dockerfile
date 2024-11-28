# base
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive

# set the github runner version
# https://github.com/actions/runner/releases
ARG RUNNER_VERSION="2.321.0"

COPY init_env.sh /tmp/init_env.sh
COPY start.sh    /tmp/start.sh

# update the base packages
RUN ls -al /tmp && chmod +x /tmp/init_env.sh && bash /tmp/init_env.sh && rm /tmp/*.sh

USER docker
WORKDIR /home/docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]

## ## build
## docker build --shm-size 512M --tag github-runner-2.321 -f github_runner.dockerfile .
##
## ## run
## docker run -e http_proxy=socks5h://192.168.0.25:9090 -e https_proxy=socks5h://192.168.0.25:9090 -e RUNNER_REPOSITORY_URL=<YOUR-REPO-URL> -e ACCESS_TOKEN=<YOUR-GITHUB-ACCESS-TOKEN> -v /dev/shm:/dev/shm --name runner --detach --restart unless-stopped github-runner-2.321
