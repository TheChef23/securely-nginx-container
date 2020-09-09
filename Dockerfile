FROM alpine
RUN apk add curl
RUN curl -L -o securely-blocker.zip 'https://git.securely.ai/securely/common/blocker/-/jobs/artifacts/master/download?job=compile' && \
    unzip securely-blocker.zip && \
    rm securely-blocker.zip

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.9.1-amd64.deb

FROM owasp/modsecurity-crs:v3.2-modsec2-apache
LABEL maintainer="franziska.buehler@owasp.org"
ENV SEC_RULE_ENGINE On

COPY --from=0 securely-blocker /usr/local/
RUN touch /etc/securely-blocker-db

COPY --from=0 filebeat-*.deb /
RUN dpkg -i /filebeat-*.deb && rm /filebeat-*.deb
RUN apt-get update && apt-get install \
      lua-socket && \
    rm -rf /var/lib/apt/lists/*

COPY 403.html /var/www/html/error/
COPY CRS-logo-full_size-512x257.png /var/www/html/error/

RUN mkdir /var/log/apache2/audit

COPY modsecurity.conf /etc/modsecurity.d/modsecurity.conf
COPY filebeat/filebeat.yml /etc/filebeat/filebeat.yml
COPY httpd-virtualhost.tpl /etc/apache2/conf/
COPY httpd.conf /etc/apache2/conf/httpd.conf

COPY lua /usr/local/bin/apache2
RUN chown -R www-data /usr/local/bin/apache2/*

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apachectl", "-f", "/etc/apache2/conf/httpd.conf", "-D", "FOREGROUND"]
