# WordPress + WP-CLI image for the wp-agent-harness toolkit.
#
# Everything here is pinned. The base image tag, the WP-CLI phar (verified
# against its published SHA-512) and the wp-cli/ability-command release are all
# build arguments supplied by docker-compose.yml from .env.
#
# This image adds nothing to WordPress itself — the MCP Adapter and MS WP
# Abilities plugins are installed at provision time by /usr/local/bin/wp-provision
# so they can be updated without rebuilding.

ARG WORDPRESS_IMAGE=wordpress:7.1.0-php8.3-apache
FROM ${WORDPRESS_IMAGE}

ARG WP_CLI_VERSION=2.12.0
ARG WP_CLI_ABILITY_COMMAND_VERSION=1.0.2

# less     — WP-CLI pager
# unzip    — WordPress plugin/theme ZIP installs
# curl     — container healthcheck and downloads below
# mariadb-client — `wp db` subcommands
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        less \
        mariadb-client \
        unzip; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# WP-CLI, pinned and checksum-verified.
# ---------------------------------------------------------------------------
RUN set -eux; \
    curl -fsSL -o /usr/local/lib/wp-cli.phar \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar"; \
    curl -fsSL -o /tmp/wp-cli.phar.sha512 \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar.sha512"; \
    echo "$(cat /tmp/wp-cli.phar.sha512)  /usr/local/lib/wp-cli.phar" | sha512sum -c -; \
    rm -f /tmp/wp-cli.phar.sha512; \
    chmod 0644 /usr/local/lib/wp-cli.phar

# ---------------------------------------------------------------------------
# wp-cli/ability-command — `wp ability list|get|run|can-run|validate`.
#
# The package declares wp-cli/wp-cli ^3.0 because it is bundled with the
# not-yet-released WP-CLI 3.0, but its code only uses WP_CLI, WP_CLI\Formatter
# and WP_CLI\Utils, all of which exist in 2.12. `wp package install` would
# refuse it on that version constraint, so the release tarball is unpacked
# directly and loaded through WP-CLI's `require` config key.
#
# The package ships no autoloader of its own (Composer generates it at release
# time), so a nine-line PSR-4 shim stands in for it. Nothing about the command
# itself is reimplemented.
# ---------------------------------------------------------------------------
COPY ability-command-autoload.php /usr/local/lib/ability-command-autoload.php

RUN set -eux; \
    mkdir -p /usr/local/lib/wp-cli-packages/ability-command; \
    curl -fsSL -o /tmp/ability-command.tar.gz \
        "https://github.com/wp-cli/ability-command/archive/refs/tags/v${WP_CLI_ABILITY_COMMAND_VERSION}.tar.gz"; \
    tar -xzf /tmp/ability-command.tar.gz --strip-components=1 \
        -C /usr/local/lib/wp-cli-packages/ability-command; \
    rm -f /tmp/ability-command.tar.gz; \
    mkdir -p /usr/local/lib/wp-cli-packages/ability-command/vendor; \
    mv /usr/local/lib/ability-command-autoload.php \
        /usr/local/lib/wp-cli-packages/ability-command/vendor/autoload.php

# ---------------------------------------------------------------------------
# WP-CLI global configuration and root-safe wrapper.
# ---------------------------------------------------------------------------
ENV WP_CLI_CONFIG_PATH=/usr/local/etc/wp-cli.yml \
    WP_CLI_CACHE_DIR=/tmp/wp-cli-cache \
    WP_CLI_PACKAGES_DIR=/usr/local/lib/wp-cli-packages

COPY apache-wordpress.conf /etc/apache2/conf-available/zz-wp-agent-harness.conf
RUN a2enconf zz-wp-agent-harness

COPY wp-cli.yml /usr/local/etc/wp-cli.yml
COPY bin/wp /usr/local/bin/wp
COPY bin/wp-provision /usr/local/bin/wp-provision
COPY bin/wp-app-password /usr/local/bin/wp-app-password

RUN set -eux; \
    chmod 0755 /usr/local/bin/wp /usr/local/bin/wp-provision /usr/local/bin/wp-app-password; \
    mkdir -p "$WP_CLI_CACHE_DIR"; \
    chown -R www-data:www-data "$WP_CLI_CACHE_DIR"; \
    wp --info >/dev/null; \
    wp help ability >/dev/null
