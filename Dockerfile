FROM alpine:latest AS builder

COPY hashicorp.asc hashicorp.asc
RUN apk add --update git curl openssh gpgme && \
    gpg --import hashicorp.asc

ARG TERRAFORM_VERSION
ENV TERRAFORM_VERSION ${TERRAFORM_VERSION:-0.11.13}

LABEL TERRAFORM_VERSION=${TERRAFORM_VERSION}

RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig && \
    gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    cat terraform_${TERRAFORM_VERSION}_SHA256SUMS | grep linux_amd64.zip | sha256sum -c && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin

FROM golang:alpine

COPY --from=builder /bin/terraform /bin/terraform
RUN apk add --update git curl gcc musl-dev

# Install dep for golang for terratest
RUN mkdir -p /root/go/bin
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
ENV GOPATH=/root/go
ENV PATH=${PATH}:/root/go/bin

ENTRYPOINT ["/bin/terraform"]