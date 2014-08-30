set terminal png size 900,300 enhanced
set output 'history_long.png'

set title "Letzte 500 Samples"
set style data fsteps
set xlabel "Zeit"
set timefmt "%m/%d/%y-%H:%M:%S"
set yrange [ 0 : 4 ]
set xdata time
set ylabel "Schnarchlevel"
set ytics 0,1
set format y ""
set ytics add ("schlaeft" 1)
set ytics add ("wach" 2)
set ytics add ("nuckelt" 3)
set format x "%a %d\n%H:%M"
set grid
set key left
plot 'plot_long.dat' using 1:2 t ""
