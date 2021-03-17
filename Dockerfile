FROM mcr.microsoft.com/dotnet/sdk:3.1
RUN apt update && \
    apt install -y apt-transport-https ca-certificates xz-utils curl jq gnupg perl python3-pip git unzip && \
    curl -L https://git.io/n-install | bash -s -- -y && \
    curl -L https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    pip3 install octokitpy requests

RUN apt install -y npm && \
    npm install sfdx-cli@7.82.1-0 --global && \
    sfdx --version
    
ENV SFDX_AUTOUPDATE_DISABLE=true SFDX_USE_GENERIC_UNIX_KEYCHAIN=true SFDX_DOMAIN_RETRY=300

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html#install-iam-authenticator-linux
# https://kubernetes.io/docs/tasks/tools/install-kubectl/
# https://carvel.dev/#whole-suite
# https://docs.cloudfoundry.org/cf-cli/install-go-cli.html
RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.3/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    curl -sL "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    curl -L https://k14s.io/install.sh | bash && \
    curl -sL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=6.51.0&source=github" | tar -zx -C /usr/local/bin

RUN apt-key adv --fetch-keys https://packages.microsoft.com/keys/microsoft.asc && \
    echo "deb https://packages.microsoft.com/repos/microsoft-debian-buster-prod buster main" >> /etc/apt/sources.list && \
    apt update && \
    apt install -y powershell && \
    pwsh --version

# https://octopus.com/downloads/tentacle#linux
RUN apt-key adv --fetch-keys https://apt.octopus.com/public.key && \
    echo 'deb https://apt.octopus.com/ stretch main' >> /etc/apt/sources.list && \
    apt update && \
    apt install -y tentacle && \
    /opt/octopus/tentacle/Tentacle version

WORKDIR /opt/octopus/tentacle/

# https://octopus.com/docs/infrastructure/deployment-targets/linux/tentacle
RUN ./Tentacle create-instance --config "/etc/octopus/default/tentacle-default.config" && \
    ./Tentacle new-certificate --if-blank && \
    ./Tentacle configure --noListen True --reset-trust --app "/home/Octopus/Applications/"

CMD [ "sh", "-c", "./Tentacle register-worker --server $serverUrl --apiKey $apiKey --workerPool $workerPool --force --comms-style TentacleActive && script -qefc './Tentacle agent' -"]
