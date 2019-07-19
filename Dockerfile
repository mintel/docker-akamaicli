FROM alpine:3.10 AS builder

RUN apk -U add build-base curl

WORKDIR /tmp

ENV JSONNET_VERSION=0.12.1 \                                                                                                            
    JSONNET_SHA256=257c6de988f746cc90486d9d0fbd49826832b7a2f0dbdb60a515cc8a2596c950

RUN curl -L https://github.com/google/jsonnet/archive/v${JSONNET_VERSION}.tar.gz -o /tmp/jsonnet.tar.gz && \
    echo "$JSONNET_SHA256  jsonnet.tar.gz" | sha256sum -c && \
    tar zxvf /tmp/jsonnet.tar.gz  -C /tmp && \                                                                                        
    cd /tmp/jsonnet-$JSONNET_VERSION && make && mv jsonnet /usr/local/bin && chmod a+x /usr/local/bin/jsonnet && cd - && \
    rm -rf /tmp/jsonnet.tar.gz /tmp/jsonnet-$JSONNET_VERSION

# Imported from : https://github.com/akamai/cli/blob/master/Dockerfile
FROM alpine:3.10 
ENV AKAMAI_CLI_HOME=/cli \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/gopath/bin \
    AKAMAICLI_VERSION=1.1.4 \
    AKAMAICLI_SHA256=bd7b6d150c62432398df4f20bfd3032cf701d2b16444309eaa830a1c1823d28b

RUN mkdir /cli && \
    apk add --no-cache bash git python2 python2-dev py2-pip python3 python3-dev wget jq openssl openssl-dev  curl nodejs build-base libffi libffi-dev go npm make openssh && \
    pip2 install --upgrade pip && \
    pip3 install --upgrade pip && \
    curl -Lo /usr/local/bin/akamaicli https://github.com/akamai/cli/releases/download/${AKAMAICLI_VERSION}/akamai-${AKAMAICLI_VERSION}-linuxamd64 && \
    cd /usr/local/bin && \
    chmod +x /usr/local/bin/akamaicli && \
    echo "$AKAMAICLI_SHA256  akamaicli" | sha256sum -c && \
    mkdir -p /cli/.akamai-cli && \
    akamaicli install --force adaptive-acceleration appsec auth cps dns firewall image-manager netstorage property property-manager purge visitor-prioritization

RUN echo "[cli]" > /cli/.akamai-cli/config && \
    echo "cache-path            = /cli/.akamai-cli/cache" >> /cli/.akamai-cli/config && \
    echo "config-version        = 1" >> /cli/.akamai-cli/config && \
    echo "enable-cli-statistics = false" >> /cli/.akamai-cli/config && \
    echo "last-ping             = 2018-04-27T18:16:12Z" >> /cli/.akamai-cli/config && \
    echo "client-id             =" >> /cli/.akamai-cli/config && \
    echo "install-in-path       =" >> /cli/.akamai-cli/config && \
    echo "last-upgrade-check    = ignore" >> /cli/.akamai-cli/config

COPY --from=builder /usr/local/bin/jsonnet /usr/local/bin/jsonnet

RUN addgroup -S mintel -g 1000 && adduser -S mintel -G mintel -h /home/mintel -u 1000 -s /bin/bash && \
    chown -R 1000:1000 /cli

USER mintel 

WORKDIR /home/mintel

ENTRYPOINT ["/usr/bin/env"]
CMD ["bash"]
