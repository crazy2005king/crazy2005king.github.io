set BLOGROOTPATH=H:
echo BLOGROOTPATH=%BLOGROOTPATH%

set IMGPATH=.\food\
echo IMGPATH=%IMGPATH%


set FILENAME1=2016food001
echo FILENAME1=%FILENAME1%


convert -resize 192 %IMGPATH%%FILENAME1%.jpg %FILENAME1%_sl.jpg 

convert %FILENAME1%_sl.jpg  -gravity southeast -fill black -pointsize 16 -draw "text 5,5 'www.ckwang.win'" %FILENAME1%_s.jpg

convert %FILENAME1%.jpg -gravity southeast -fill black -pointsize 16 -draw "text 5,5 'www.ckwang.win'" %FILENAME1%_b.jpg

del %FILENAME1%_sl.jpg 

cmd

