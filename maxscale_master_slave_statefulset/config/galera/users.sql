RESET MASTER;
CREATE DATABASE test;

CREATE USER '{{ .Values.REPLICATION_USERNAME }}'@'127.0.0.1' IDENTIFIED BY '{{ .Values.REPLICATION_PASSWORD }}';
CREATE USER '{{ .Values.REPLICATION_USERNAME }}'@'%' IDENTIFIED BY '{{ .Values.REPLICATION_PASSWORD }}';
GRANT ALL ON *.* TO '{{ .Values.REPLICATION_USERNAME }}'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '{{ .Values.REPLICATION_USERNAME }}'@'%' WITH GRANT OPTION;

CREATE USER '{{ .Values.ADMIN_USERNAME }}'@'127.0.0.1' IDENTIFIED BY '{{ .Values.ADMIN_PASSWORD }}';
CREATE USER '{{ .Values.ADMIN_USERNAME }}'@'%' IDENTIFIED BY '{{ .Values.ADMIN_PASSWORD }}';
GRANT ALL ON *.* TO '{{ .Values.ADMIN_USERNAME }}'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '{{ .Values.ADMIN_USERNAME }}'@'%' WITH GRANT OPTION;

SET GLOBAL max_connections=10000;
SET GLOBAL gtid_strict_mode=ON;
