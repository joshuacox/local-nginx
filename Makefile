.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container

build: NAME TAG builddocker

# run a  container temporarily to grab the config directory
temp: rm build runtemp

prod: NGINX_DATADIR rm build runprod

runtemp:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-d \
	-P \
	-t $(TAG)

runprod:
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	echo " the nginx data dir is $(NGINX_DATADIR)"
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-d \
	-p 80:80 \
	-p 443:443 \
	-v $(NGINX_DATADIR)/etc/nginx:/etc/nginx \
	-v $(NGINX_DATADIR)/html:/usr/share/nginx/html \
	-v "$(NGINX_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-t $(TAG)

builddocker:
	/usr/bin/time -v docker build -t `cat TAG` .

kill:
	-@docker kill `cat cid`

rm-image:
	-@docker rm `cat cid`
	-@rm cid

rm: kill rm-image

clean: rm

enter:
	docker exec -i -t `cat cid` /bin/bash

logs:
	docker logs -f `cat cid`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

rmall: rm

grab: grabnginxdir mvdatadir

grabnginxdir:
	mkdir -p datadir/etc
	docker cp `cat cid`:/usr/share/nginx/html - |sudo tar -C datadir/ -pxvf -
	docker cp `cat cid`:/etc/nginx - |sudo tar -C datadir/etc -pxvf -
	sudo chown -R $(user). datadir/html
	sudo chown -R $(user). datadir/etc

mvdatadir:
	sudo mv -i datadir /tmp
	echo /tmp/datadir > NGINX_DATADIR
	echo "Move datadir out of tmp and update DATADIR here accordingly for persistence"

NGINX_DATADIR:
	@while [ -z "$$NGINX_DATADIR" ]; do \
		read -r -p "Enter the destination of the nginx data directory you wish to associate with this container [NGINX_DATADIR]: " NGINX_DATADIR; echo "$$NGINX_DATADIR">>NGINX_DATADIR; cat NGINX_DATADIR; \
	done ;

newcert: rmcertstuff CERTSITE CERTMAIL rm mkcert runprod

rmcertstuff:
	-@rm CERTSITE
	-@rm CERTMAIL

CERTSITE:
	@while [ -z "$$CERTSITE" ]; do \
		read -r -p "Enter the site name you wish to retrieve a certificate for [CERTSITE]: " CERTSITE; echo "$$CERTSITE">>CERTSITE; cat CERTSITE; \
	done ;

CERTMAIL:
	@while [ -z "$$CERTMAIL" ]; do \
		read -r -p "Enter the site email [CERTMAIL]: " CERTMAIL; echo "$$CERTMAIL">>CERTMAIL; cat CERTMAIL; \
	done ;

mkcert:
	$(eval CERTSITE := $(shell cat CERTSITE))
	$(eval CERTMAIL := $(shell cat CERTMAIL))
	~/git/certbot/certbot-auto certonly --standalone -n -d $(CERTSITE) --email "$(CERTMAIL)"
