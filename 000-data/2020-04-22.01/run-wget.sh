#!/bin/bash

wget https://www12.statcan.gc.ca/census-recensement/2016/dp-pd/dt-td/CompDataDownload.cfm?LANG=E\&PID=109523\&OFT=CSV
mv CompDataDownload.cfm* 98-400-X2016001_ENG_CSV.ZIP
unzip 98-400-X2016001_ENG_CSV.ZIP

chmod ugo-w 98-400-X2016001*
chmod ugo-w Geo_starting_row_CSV.csv
chmod ugo-w README_meta.txt
chmod ugo-w std*.sh.wget

