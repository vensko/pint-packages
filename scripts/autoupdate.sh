#!/bin/bash

cd /home/ego/pint/pint-packages

git pull

cd scripts

pwsh import-sps.ps1
unlink sps.zip

pwsh "import-portableapps.com.ps1"
pwsh import-nirsoft.ps1
pwsh import-sordum.ps1
pwsh import-sysinternals.ps1

pwsh compile-db.ps1

cd ..

git add -A
git commit -m "Autoupdate"
git push
