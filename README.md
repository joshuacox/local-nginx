# local-nginx

local-nginx docker container with everything built locally

### Requirements

You will need a locally built stretch image named local-stretch. I have another repo  [here](https://github.com/joshuacox/local-debian)
that automates the creation of that.

### Usage

You can quickly get a temp instance up with:

```
make temp
```

### Persistence

You can `grab` the necessary config directories out of the running temp instance using:

```
make grab
```

then kill off the initial instance

```
make rm
```

and start up a persistent instance with the data directories mounted in:

```
make prod
```

### Data Directory

You can move it wherever you like just update the contents of the `NGINX_DATADIR` file:

```
cat git/local-nginx/NGINX_DATADIR
/exports/nginx/datadir
```

### Nusite

```
make nusite
```

will prompt you for a few details and then copy `templates/site.template` into your NGNIX_DATADIR

for example for hostname.example.com, you would enter:

```
Enter the name you wish to associate with this container [SITENAME]: hostname
hostname
Enter the name you wish to associate with this container [DOMAIN]: example.com
example.com
```

### Let's Encrypt

NOTE: the above `make nusite` does this automatically now

you can automate the retrieval and creation of SSL/TLS certificates using Let's Encrypt

```
make newcert
```

and you will be prompted for an email address and the FQDN of the site to be registered

it should be noted that the nginx container will go down momentarily while the lets encrypt container takes control of port 443

Of note there is another promising project [here](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion) which eliminates the downtime.  When I get a chance I'll work on integrating that functionality.


### Kubernetes

To get a kubernetes version of this container you can incant the `k8s` recipe:

```
make k8s
```

### Contributing

Issues and Pull requests are welcome
