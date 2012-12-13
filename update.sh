#!/bin/bash
rm GeoLiteCity.dat.gz 
/usr/bin/wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && rm GeoLiteCity.dat && gunzip GeoLiteCity.dat.gz
