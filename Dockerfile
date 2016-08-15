FROM local-stretch
MAINTAINER Josh Cox <josh 'at' webhosting.coop>

ENV DOCKER_PROTOTYPE 20160511
ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
#ENV NGINX_VERSION 1.9.9-1~stretch
#apt-get install -y ca-certificates nginx=${NGINX_VERSION} && \

RUN echo 'deb http://ftp.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/backports.list ; \
apt-get -qq update ; \
apt-get -qqy dist-upgrade ; \
apt-get -qqy --no-install-recommends install locales \
sudo procps ca-certificates wget pwgen supervisor; \
apt-get install -y ca-certificates nginx letsencrypt git && \
mkdir /git; cd /git; git clone https://github.com/certbot/certbot && \
cd /git/certbot; ./certbot-auto -n && \
echo 'en_US.ISO-8859-15 ISO-8859-15'>>/etc/locale.gen ; \
echo 'en_US ISO-8859-1'>>/etc/locale.gen ; \
echo 'en_US.UTF-8 UTF-8'>>/etc/locale.gen ; \
locale-gen ; \
apt-get -y autoremove ; \
apt-get clean ; \
rm -Rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN touch /var/log/nginx/access.log ; \
touch /var/log/nginx/error.log ; \
ln -sf /dev/stdout /var/log/nginx/access.log ; \
ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
