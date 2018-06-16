FROM jenkins/jnlp-slave:3.19-1-alpine

USER root

COPY entrypoint.sh /

RUN apk --update add tzdata curl dpkg openssl maven docker && \
    # maven site doesn't work without the fonts
    apk add msttcorefonts-installer fontconfig && \
    # configure font
    update-ms-fonts && fc-cache -f && \
    # surefire 2.21.0+ issue without procps
    apk add procps && \
    # install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    curl -fsSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$dpkgArch" -o /usr/local/bin/gosu && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    # complete gosu
    chmod u+x /entrypoint.sh && \
    apk del dpkg && \
    rm -rf /apk /tmp/* /var/cache/apk/*

#USER jenkins
ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["gosu", "jenkins", "jenkins-slave"]
