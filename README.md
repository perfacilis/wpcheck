# Wordpress Security Hardening Checker

Totally experimental, work in progress.

Any suggestions or contributions are welcome!

## Install

The script depends on wp-cli:

```bash
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
install -m 0755 wp-cli.phar /usr/local/bin/wp
````

## Usage

```bash
bash wpcheck.sh /var/www/example.tld/httpdocs
```