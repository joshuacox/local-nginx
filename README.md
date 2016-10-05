# local-nginx

local-nginx docker container with everything built locally

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

then kill of the initial instance

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
