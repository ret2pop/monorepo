{ config, lib, services, ... }:
{
  services.nginx = {
    enable = lib.mkDefault config.monorepo.profiles.server.enable;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    appendHttpConfig = ''
  # Add HSTS header with preloading to HTTPS requests.
  # Adding this header to HTTP requests is discouraged
  map $scheme $hsts_header {
	https   "max-age=31536000; includeSubdomains; preload";
  }
  add_header Strict-Transport-Security $hsts_header;

  # Enable CSP for your services.
  #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

  # Minimize information leaked to other domains
  add_header 'Referrer-Policy' 'origin-when-cross-origin';

  # Disable embedding as a frame
  add_header X-Frame-Options DENY;

  # Prevent injection of code in other mime types (XSS Attacks)
  add_header X-Content-Type-Options nosniff;

  # This might create errors
  proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
'';

    virtualHosts = {
	    "ret2pop.nullring.xyz" = {
	      # addSSL = true;
	      # enableACME = true;
	      root = "/home/preston/ret2pop-website/";
	    };
    };
  };
}
