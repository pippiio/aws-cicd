FROM amazon/aws-cli

ENV LC_CTYPE=en_US.utf-8

# RUN yum -y install unzip tar gzip shadow-utils.x86_64 iptables openssl python3 pip java jq git hugo
RUN yum upgrade -y \
    && yum update -y \
    && yum -y install iptables unzip tar gzip shadow-utils.x86_64 openssl python3 pip jq git \
    && pip3 install yq

# ==== Hugo ====
ENV HUGO_BUCKET="github.com/gohugoio/hugo" \
    HUGO_VERSION="0.92.0" \
    HUGO_SHA256="5305401d4618a18d06ea5e21913c4be55b279a8dacc69e3add36a9bb9b11cb4d"

RUN curl -s -qL -o hugo_Linux-64bit.tar.gz  https://${HUGO_BUCKET}/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
    && echo "${HUGO_SHA256} hugo_Linux-64bit.tar.gz" | sha256sum -c - \
    && tar --extract --file hugo_Linux-64bit.tar.gz --directory /usr/local/bin \
    && rm hugo_Linux-64bit.tar.gz \
    && hugo version

# ==== Hugo END ====

# ==== Docker 20.10.9 ====
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="1.26.0"

ENV DOCKER_SHA256="caf74e54b58c0b38bb4d96c8f87665f29b684371c9a325562a3904b8c389995e"
ENV DOCKER_VERSION="20.10.9"

VOLUME /var/lib/docker

RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && curl -s -qL -o /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" \
    && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
    && docker-compose version
# ==== Docker 20.10.9 END ====

RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash

# ==== Terraform ====
# https://releases.hashicorp.com/terraform/1.1.2/terraform_1.1.2_SHA256SUMS
ENV TF_BUCKET="releases.hashicorp.com" \
    TF_SHA256="b87de03adbdfdff3c2552c8c8377552d0eecd787154465100cf4e29de4a7be1f" \
    TF_VERSION=1.2.0

RUN curl -s -qL -o terraform_install.zip "https://${TF_BUCKET}/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" \
    && echo "${TF_SHA256} *terraform_install.zip" | sha256sum -c - \
    && unzip "terraform_install.zip" -d /usr/bin/ \
    && rm terraform_install.zip \
    $$ terraform --version
# ==== Terraform END ====

# ==== NodeJS ====
ENV NODE_VERSION=14

RUN curl -sL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && yum install -y nodejs \
    && npm install -g npm 

# ==== NodeJS END ====

COPY dockerd-entrypoint.sh /usr/local/bin/
RUN chmod +x "/usr/local/bin/dockerd-entrypoint.sh"

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]
