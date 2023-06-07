#!/bin/bash
path=`sudo -u postgres psql -c 'show data_directory;' | grep -E 'postgres'` 
sudo cp ./part1/csv/*.csv $path