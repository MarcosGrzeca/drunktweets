#!/bin/sh

cd /var/www/html/drunktweets/
git pull
git add *
git commit -m "Teste"
git push
