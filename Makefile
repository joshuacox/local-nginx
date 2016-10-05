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
	-v "$(NGINX_DATADIR)/etc/nginx:/etc/nginx" \
	-v "$(NGINX_DATADIR)/html:/usr/share/nginx/html" \
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

REGISTRY:
	@while [ -z "$$REGISTRY" ]; do \
		read -r -p "Enter the registry you wish to associate with this container [REGISTRY]: " REGISTRY; echo "$$REGISTRY">>REGISTRY; cat REGISTRY; \
	done ;

REGISTRY_PORT:
	@while [ -z "$$REGISTRY_PORT" ]; do \
		read -r -p "Enter the port of the registry you wish to associate with this container, usually 5000 [REGISTRY_PORT]: " REGISTRY_PORT; echo "$$REGISTRY_PORT">>REGISTRY_PORT; cat REGISTRY_PORT; \
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

push: TAG REGISTRY REGISTRY_PORT
	$(eval TAG := $(shell cat TAG))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	docker tag $(TAG) $(REGISTRY):$(REGISTRY_PORT)/$(TAG)
	docker push $(REGISTRY):$(REGISTRY_PORT)/$(TAG)

local-nginx-svc.yaml: NGINX_DATADIR REGISTRY REGISTRY_PORT TAG NAME
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	$(eval TAG := $(shell cat TAG))
	$(eval NAME := $(shell cat NAME))
	cp -i templates/local-nginx-svc.template local-nginx-svc.yaml
	sed -i "s!REPLACEME_DATADIR!$(NGINX_DATADIR)!g" local-nginx-svc.yaml
	sed -i "s/REPLACEME_REGISTRY/$(REGISTRY)/g" local-nginx-svc.yaml
	sed -i "s/REPLACEME_PORT_OF_REGISTRY/$(REGISTRY_PORT)/g" local-nginx-svc.yaml
	sed -i "s!REPLACEME_TAG!$(TAG)!g" local-nginx-svc.yaml
	sed -i "s!REPLACEME_NAME!$(NAME)!g" local-nginx-svc.yaml

local-nginx-deploy.yaml: NGINX_DATADIR REGISTRY REGISTRY_PORT TAG NAME
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	$(eval TAG := $(shell cat TAG))
	$(eval NAME := $(shell cat NAME))
	cp -i templates/local-nginx-deploy.template local-nginx-deploy.yaml
	sed -i "s!REPLACEME_DATADIR!$(NGINX_DATADIR)!g" local-nginx-deploy.yaml
	sed -i "s/REPLACEME_REGISTRY/$(REGISTRY)/g" local-nginx-deploy.yaml
	sed -i "s/REPLACEME_PORT_OF_REGISTRY/$(REGISTRY_PORT)/g" local-nginx-deploy.yaml
	sed -i "s!REPLACEME_TAG!$(TAG)!g" local-nginx-deploy.yaml
	sed -i "s!REPLACEME_NAME!$(NAME)!g" local-nginx-deploy.yaml

k8s: k8deploy k8svc

k8svc: local-nginx-svc.yaml
	kubectl create -f local-nginx-svc.yaml

k8deploy: local-nginx-deploy.yaml
	kubectl create -f local-nginx-deploy.yaml

site: SITENAME DOMAIN IP PORT NGINX_DATADIR
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval PORT := $(shell cat PORT))
	$(eval IP := $(shell cat IP))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval SITENAME := $(shell cat SITENAME))
	echo $(PORT)
	echo $(SITENAME)
	echo $(DOMAIN)
	echo "$(SITENAME).$(DOMAIN)" > CERTSITE
	echo "webmaster@$(SITENAME).$(DOMAIN)" > CERTMAIL
	cp template/site.template $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_PORT/$(PORT)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_IP/$(IP)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_DOMAIN/$(DOMAIN)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_SITENAME/$(SITENAME)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	cat $(TMP)/$(SITENAME).$(DOMAIN)
	sudo cp $(TMP)/$(SITENAME).$(DOMAIN) $(NGINX_DATADIR)/etc/nginx/sites-available/
	cd $(NGINX_DATADIR)/etc/nginx/sites-enabled/ ; \
	sudo rm -f $(SITENAME).$(DOMAIN)  ; \
	sudo ln -s ../sites-available/$(SITENAME).$(DOMAIN) ./
	ls -lh $(NGINX_DATADIR)/etc/nginx/sites-enabled/ 
	rm -Rf $(TMP)

nusite: cleansite site mkcert

cleansite:
	-@rm SITENAME
	-@rm PORT
	-@rm DOMAIN
	-@rm IP

SITENAME:
	@while [ -z "$$SITENAME" ]; do \
		read -r -p "Enter the sitename you wish to associate with this container [SITENAME e.g. 'www']: " SITENAME; echo "$$SITENAME">>SITENAME; cat SITENAME; \
	done ;

DOMAIN:
	@while [ -z "$$DOMAIN" ]; do \
		read -r -p "Enter the DOMAIN you wish to associate with this container [DOMAIN e.g. 'example.com']: " DOMAIN; echo "$$DOMAIN">>DOMAIN; cat DOMAIN; \
	done ;

IP:
	@while [ -z "$$IP" ]; do \
		read -r -p "Enter the IP you wish to associate with this container [IP e.g. '192.168.1.133']: " IP; echo "$$IP">>IP; cat IP; \
	done ;

PORT:
	@while [ -z "$$PORT" ]; do \
		read -r -p "Enter the PORT you wish to associate with this container [PORT e.g. '8080']: " PORT; echo "$$PORT">>PORT; cat PORT; \
	done ;
