# Install

!!! info "Docker"
    
    Docker production installation is not yet supported. See [issue #352](https://framagit.org/framasoft/mobilizon/issues/352).

## Pre-requisites

* A Linux machine with **root access**
* A **domain name** (or subdomain) for the Mobilizon server, e.g. `example.net`
* An **SMTP server** to deliver emails

## Dependencies

Mobilizon requires Elixir, NodeJS and PostgreSQL among other things.  

Installing dependencies depends on the system you're using. Follow the steps of the [dependencies guide](dependencies.md).

## Setup

We're going to use a dedicated `mobilizon` user with `/home/mobilizon` home:
```bash
sudo adduser --disabled-login mobilizon
```

!!! tip

    On FreeBSD
    
    ``` bash
    sudo pw useradd -n mobilizon -d /home/mobilizon -s /usr/local/bin/bash -m 
    sudo passwd mobilizon
    ```

Then let's connect as this user:

```bash
sudo -i -u mobilizon
```

Let's start by cloning the repository in a directory named `live`:

```bash
git clone https://framagit.org/framasoft/mobilizon live && cd live
```


## Installing dependencies

Install Elixir dependencies

```bash
mix deps.get
```

Then compile these dependencies and Mobilizon (this can take a few minutes)

```bash
mix compile
```

Go into the `js/` directory

```bash
cd js
```

and install the Javascript dependencies

```bash
yarn install
```

Finally, we can build the front-end (this can take a few seconds)
```bash
NODE_ENV=production yarn run build
```

Let's go back to the main directory
```bash
cd ../
```

## Configuration

Mobilizon provides a command line tool to generate configuration

```bash
mix mobilizon.instance gen
```

This will ask you questions about your setup and your instance to generate a `prod.secret.exs` file in the `config/` folder, and a `setup_db.psql` file to setup the database.

### Database setup

The `setup_db.psql` file contains SQL instructions to create a PostgreSQL user and database with the chosen credentials and add the required extensions to the Mobilizon database.

Execute
```bash
sudo -u postgres psql -f setup_db.psql
```

!!! warning

    When it's done, don't forget to remove the `setup_db.psql` file.

### Database Migration

Run database migrations: 
```bash
MIX_ENV=prod mix ecto.migrate
```

!!! note

    Note the `MIX_ENV=prod` environment variable prefix in front of the command. You will have to use it for each `mix` command from now on.

You will have to do this again after most updates.

!!! tip
    If some migrations fail, it probably means you're not using a recent enough version of PostgreSQL, or that you haven't installed the required extensions.

## Services

### Systemd

Copy the `support/systemd/mobilizon.service` to `/etc/systemd/system`.

```bash
sudo cp support/systemd/mobilizon.service /etc/systemd/system/
```

Reload Systemd to detect your new file

```bash
sudo systemctl daemon-reload
```

And enable the service

```bash
systemctl enable --now mobilizon.service
```

It will run Mobilizon and enable startup on boot. You can follow the logs with

```bash
sudo journalctl -fu mobilizon.service
```

The Mobilizon server runs on port 4000 on the local interface only, so you need to add a reverse-proxy.

## Reverse proxy

### Nginx

Copy the file from `support/nginx/mobilizon.conf` to `/etc/nginx/sites-available`.

```bash
sudo cp support/nginx/mobilizon.conf /etc/nginx/sites-available
```

Then symlink the file into the `/etc/nginx/sites-enabled` directory.

```bash
sudo ln -s /etc/nginx/sites-available/mobilizon.conf /etc/nginx/sites-enabled/
```

Edit the file `/etc/nginx/sites-available` and adapt it to your own configuration.

Test the configuration with `sudo nginx -t` and reload nginx with `systemctl reload nginx`.

## Optional tasks

### Geolocation databases

Mobilizon can use geolocation from MMDB format data from sources like [MaxMind GeoIP](https://dev.maxmind.com/geoip/geoip2/geolite2/) databases or [db-ip.com](https://db-ip.com/db/download/ip-to-city-lite) databases. This allows showing events happening near the user's location.

You will need to download the City database and put it into `priv/data/GeoLite2-City.mmdb`.

Mobilizon will only show a warning at startup if the database is missing, but it isn't required.