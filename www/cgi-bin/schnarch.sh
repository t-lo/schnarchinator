#!/bin/bash

logfile="../log.dat"
plot_short="../plot_short.dat"
plot_med="../plot_med.dat"
plot_long="../plot_long.dat"

num_samples_short=80
num_samples_med=200
num_samples_long=2000

function write_html() {
    local curr_state=`tail -1 $logfile`
    local state_num=`echo $curr_state | cut -d " " -f2`
    local state_ts=`echo $curr_state | cut -d " " -f1 | cut -d "-" -f 2`

    local state_date=`echo $state_ts | sed 's/\(..\).\(..\).\(..\).\(..\).\(..\).\(..\)/20\3\1\2 \4\5/'`
    local state_sec=$(date +%s -d "$state_date")
    local state_diff=$((`date +%s` - $state_sec))
    local state_hr=$((state_diff / 60 / 60))
    local state_min=$((state_diff / 60 - $state_hr * 60))
    local state_sec=$((state_diff % 60))

    local state=""
    case $state_num in
        1) state="schl&auml;ft";;
        2) state="wach";;
        3) state="nuckelt";;
    esac

    echo -en 'content-type:text/html; charset=utf-8\r\n\r\n'
    cat << EOF
<html>
    <head>

        <link rel="stylesheet" type="text/css" href="../index.css">

    </head>
    <body>
	<center>

        <div class="titlebar" height="15%">
            <h1 style="margin-left: 5pt;">Babystatus: $state
            </h1>
            <h2> (seit $state_ts - $state_hr h, $state_min min, $state_sec s)</h2>
        </div> 

        <br clear="all"/>

        <table style="margin-top:5pt; border:none;"> <tr>
            <td style="padding:5pt; vertical-align:top;">
                <form action="schnarch.sh" method="post" > 
                    <button class="button" name="sleep" type="submit">
                        schl&auml;ft </button> </form></td>
            <td style="padding:5pt; vertical-align:top;">
                <form action="schnarch.sh" method="post" > 
                    <button class="button" name="awake" type="submit"> 
                        ist wach </button> </form></td>
            <td style="padding:5pt; vertical-align:top;">
                <form action="schnarch.sh" method="post" > 
                    <button class="button" name="feed" type="submit">
                        nuckelt </button> </form></td>
        </tr></table>

        <br clear="all" />'
        <img src="../today.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../yesterday.png?$RANDOM\" /><br clear="all"><hr width="30%">
        <img src="../before_yd.png?$RANDOM\" /><br clear="all"><hr width="30%">
        
        <img src="../week.png?$RANDOM\" /><br clear="all"><hr width="30%">
        <img src="../month.png?$RANDOM\" />
	</center>
</body></html> 
EOF
}
# ----

function redirect() {
    echo -en 'content-type:text/html; charset=utf-8\r\n\r\n'
    echo '
        <html>
        <head>
        <META HTTP-EQUIV=Refresh CONTENT="0; URL=schnarch.sh">
        </head>
        </html>
        '
}
# ----

function plot() {
    local from="$1"
    local to="$2"
    local plot_name="$3"
    local desc="$4"

    local plot_cfg=`mktemp`

    cat >"$plot_cfg" << EOF
    set terminal png size 900,300 enhanced
    set output '$plot_name.png'

    set title "$desc"
    set style data fsteps
    set xlabel "Zeit"
    set xdata time
    set timefmt "%m/%d/%y-%H:%M:%S"
    set xrange [ "$from" : "$to" ]
    set yrange [ 0 : 4 ]
    set ylabel "Schnarchlevel"
    set ytics 0,1
    set format y ""
    set ytics add ("schlaeft" 1)
    set ytics add ("wach" 2)
    set ytics add ("nuckelt" 3)
    set format x "%a %d\\n%H:%M"
    set grid
    set key left
    plot 'log.dat' using 1:2 index 0 t "" with lines
EOF

    gnuplot "$plot_cfg"
    rm "$plot_cfg"
}
# ----

function generate_plots() {
    local today="`date +%D-%H:%M:%S -d 0`"
    local tomorrow="`date +%D-%H:%M:%S -d \"+1day 0\"`"
    local yesterday="`date +%D-%H:%M:%S -d \"-1day 0\"`"
    local before_yd="`date +%D-%H:%M:%S -d \"-2day 0\"`"

    local last_week="`date +%D-%H:%M:%S -d \"-7day 0\"`"
    local last_month="`date +%D-%H:%M:%S -d \"-30day 0\"`"

    (   cd ..;
        plot "$today" "$tomorrow" "today" "Heute"
        plot "$yesterday" "$today" "yesterday" "Gestern"
        plot "$before_yd" "$yesterday" "before_yd" "Vorgestern"
        plot "$last_week" "$tomorrow" "week" "Letzte Woche"
        plot "$last_month" "$tomorrow" "month" "Letzter Monat"
    )

}
# ----

function add_log() {
    local what="$1"
    local last_state=`tail -1 $logfile | cut -d " " -f2`
    local ts="`date +%D-%H:%M:%S`"

    if [ "$what" != "$last_state" ]; then
        echo "$ts $last_state" >> "$logfile"
        echo "$ts $what" >> "$logfile"
    fi

    generate_plots
    redirect
}
# ----

#
# MAIN
#

if [ "$REQUEST_METHOD" = "POST" ] ; then
    data="$(</dev/stdin)"
    case "$data" in
        sleep*) add_log "1";;
        awake*) add_log "2";;
        feed*)  add_log "3";;
    esac
else
    write_html
fi
