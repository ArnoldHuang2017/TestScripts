echo xxx > d:\s.txt
echo xxx > e:\s.txt
echo xxx > f:\s.txt


echo | set /p =%DATE%, %time%,,,,>>C:\\Temp\Haswellresult.csv


IF NOT EXIST D:s.txt echo | set /p =disk D: NOK,>>C:\\Temp\Haswellresult.csv
IF EXIST D:s.txt echo | set /p =disk D: OK,>>C:\\Temp\Haswellresult.csv

IF NOT EXIST E:s.txt echo | set /p =disk E: NOK,>>C:\\Temp\Haswellresult.csv
IF EXIST E:s.txt echo | set /p =disk E: OK,>>C:\\Temp\Haswellresult.csv

IF NOT EXIST F:s.txt echo | set /p =disk F: NOK,>>C:\\Temp\Haswellresult.csv
IF EXIST F:s.txt echo | set /p =disk F: OK,>>C:\\Temp\Haswellresult.csv

systeminfo |find "Total Physical Memory">>C:\\Temp\Haswellresult.csv


copy /y C:\\Temp\Haswellresult.csv \\10.7.60.200\rms420\powercycle\PC1.log

Shutdown -s -t 60