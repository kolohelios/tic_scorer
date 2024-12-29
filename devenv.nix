{
  pkgs,
  ...
}: let
  db_user = "tic_scorer_user";
  db_password = "tic_scorer_password";
  db_host = "localhost";
  db_port = 5432;
  db_name = "tic_scorer";
  database_url = "postgresql://${db_user}:${db_password}@${db_host}:${toString db_port}/${db_name}";
in {
  env = {
    DATABASE_URL = database_url;
  };
  packages = with pkgs; [
    ripgrep
    just
  ];

  languages.rust.enable = true;


  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16_jit;
    initialDatabases = [{name = db_name;}];
    listen_addresses = db_host;
    port = db_port;
    initialScript = ''
      -- Create the superuser
      CREATE USER ${db_user} WITH SUPERUSER CREATEDB PASSWORD '${db_password}';

      GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_password};
      ALTER DATABASE ${db_name} OWNER TO ${db_user};
    '';
  };

  processes = {
    pg-web.exec = ''
      ${pkgs.retry}/bin/retry --until=success --times=10 -- \
      ${pkgs.postgresql_16_jit}/bin/pg_isready -d ${db_name} \
      -h ${db_host} -p ${builtins.toString db_port} -U ${db_user};

      ${pkgs.pgweb}/bin/pgweb --url ${database_url} --query-timeout 3600'';
  };
}

