{ config, lib, services, ... }:
{
  services.nginx = {
    enable = lib.mkDefault config.monorepo.profiles.server.enable;
    user = "nginx";
    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    # sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    appendHttpConfig = '''';

    gitweb = {
      enable = true;
      virtualHost = "${config.monorepo.vars.remoteHost}";
    };

    virtualHosts = {
      "matrix.${config.monorepo.vars.remoteHost}" = {
        enableACME = true;
        forceSSL = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 443;
            ssl = true;
          }          {
            addr = "0.0.0.0";
            port = 8448;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 8448;
            ssl = true;
          }
        ];
        locations."/_matrix/" = {
          proxyPass = "http://127.0.0.1:6167";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_buffers 32 16k;
            proxy_read_timeout 5m;
          '';
        };

        extraConfig = ''
          merge_slashes off;
        '';
      };
	    "${config.monorepo.vars.remoteHost}" = {
        serverName = "${config.monorepo.vars.remoteHost}";
	      root = "/var/www/ret2pop-website/";
	      addSSL = true;
	      enableACME = true;
	    };
    };
  };
}
