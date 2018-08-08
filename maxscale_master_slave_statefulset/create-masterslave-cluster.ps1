# (C) 2018 MariaDB Corporation
# Creates a templatized master-slave cluster fronted by MaxScale in Kubernetes
# User-defined parameters are "application" and "environment"

param (
    [Parameter(Mandatory=$true,HelpMessage="Application Name")][string]$a,
    [Parameter(Mandatory=$true,HelpMessage="Environment Name")][string]$e
 )

# default other arguments for now
$u='mariadb-admin'
$p='mariadb-admin'
$ru='repl'
$rp='repl'

# convert secret args to base64
$u=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($u))
$p=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($p))
$ru=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ru))
$rp=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($rp))

# Change default file encoding to utf8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# create temp directories for template expansion / line ending fixes
New-Item -ItemType Directory -Force -Path .\tmp
New-Item -ItemType Directory -Force -Path .\tmp\config

# Do token replacement in yaml files and write to tmp directory
$files = Get-ChildItem .\templates\*.yaml
foreach ($file in $files) {
  $i = $file.Name
  cat .\templates\$i |
    % {$_ -replace "{{APPLICATION}}", "$a"} |
    % {$_ -replace "{{ENVIRONMENT}}", "$e"} |
    % {$_ -replace "{{ADMIN_USERNAME}}", "$u"} |
    % {$_ -replace "{{ADMIN_PASSWORD}}", "$p"} |
    % {$_ -replace "{{REPLICATION_USERNAME}}", "$ru"} |
    % {$_ -replace "{{REPLICATION_PASSWORD}}", "$rp"} `
    > .\tmp\$i
}

# ensure files that will be mounted on container have linux line endings
$files = Get-ChildItem .\templates\config
foreach ($file in $files) {
  $i = $file.Name
  Get-Content .\templates\config\$i  -raw | % {$_ -replace "`r", ""} | Set-Content -NoNewline  .\tmp\config\$i
}

# now load the yaml files from the tmp directory
kubectl create configmap mariadb-config --from-file=.\tmp\config
kubectl create -f .\tmp\mariadb-secret.yaml
kubectl create -f .\tmp\masterslave.yaml
kubectl create -f .\tmp\maxscale.yaml
