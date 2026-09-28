<?php
/**
 * PSR-4 shim standing in for the Composer autoloader that wp-cli/ability-command
 * generates at release time but does not ship in its Git tag tarball.
 *
 * Installed by docker/wordpress/Dockerfile as
 * /usr/local/lib/wp-cli-packages/ability-command/vendor/autoload.php, which is
 * exactly where ability-command.php looks for it. The class map mirrors the
 * package's own composer.json: WP_CLI\Ability\ => src/.
 *
 * @package wp-agent-harness
 */

spl_autoload_register(
	static function ( $class_name ) {
		$prefix = 'WP_CLI\\Ability\\';

		if ( 0 !== strpos( $class_name, $prefix ) ) {
			return;
		}

		$relative = substr( $class_name, strlen( $prefix ) );
		$file     = dirname( __DIR__ ) . '/src/' . str_replace( '\\', '/', $relative ) . '.php';

		if ( is_readable( $file ) ) {
			require_once $file;
		}
	}
);
