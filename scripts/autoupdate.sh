#!/bin/bash

cd /home/ego/pint/pint-packages/scripts

pwsh import-sps.ps1
unlink sps.zip

pwsh import-nirsoft.ps1
pwsh import-sordum.ps1

pwsh compile-db.ps1

cd ..

git add -A
git commit -m "Autoupdate"
git push
