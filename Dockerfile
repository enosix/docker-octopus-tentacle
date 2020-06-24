FROM mcr.microsoft.com/dotnet/core/aspnet:latest
RUN apt update && \
    apt install -y apt-transport-https curl jq gnupg perl python3-pip git && \
    curl -L https://git.io/n-install | bash -s -- -y && \
    curl -L https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    pip3 install octokitpy requests

RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.3/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    curl -sL "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    curl -L https://k14s.io/install.sh | bash

RUN apt-key adv --fetch-keys https://apt.octopus.com/public.key && \
    echo 'deb https://apt.octopus.com/ stretch main' >> /etc/apt/sources.list && \
    apt update && \
    apt install tentacle

WORKDIR /opt/octopus/tentacle/

RUN ./Tentacle create-instance --config "/etc/octopus/default/tentacle-default.config" && \
    ./Tentacle new-certificate --if-blank && \
    ./Tentacle configure --noListen True --reset-trust --app "/home/Octopus/Applications/"

CMD [ "sh", "-c", "./Tentacle register-worker --server $serverUrl --apiKey $apiKey --workerPool $workerPool --force --comms-style TentacleActive && script -qefc './Tentacle agent' -"]
