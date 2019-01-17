{{- if or (eq .Values.mariadb.cluster.topology "standalone") (eq .Values.mariadb.cluster.topology "masterslave") }}
RESET MASTER;
{{- end }}

CREATE USER '<<REPLICATION_USERNAME>>'@'127.0.0.1' IDENTIFIED BY '<<REPLICATION_PASSWORD>>';
CREATE USER '<<REPLICATION_USERNAME>>'@'%' IDENTIFIED BY '<<REPLICATION_PASSWORD>>';
GRANT ALL ON *.* TO '<<REPLICATION_USERNAME>>'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '<<REPLICATION_USERNAME>>'@'%' WITH GRANT OPTION;

CREATE USER '<<ADMIN_USERNAME>>'@'127.0.0.1' IDENTIFIED BY '<<ADMIN_PASSWORD>>';
CREATE USER '<<ADMIN_USERNAME>>'@'%' IDENTIFIED BY '<<ADMIN_PASSWORD>>';
GRANT ALL ON *.* TO '<<ADMIN_USERNAME>>'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '<<ADMIN_USERNAME>>'@'%' WITH GRANT OPTION;

SET GLOBAL max_connections=10000;
SET GLOBAL gtid_strict_mode=ON;