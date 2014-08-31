#!/bin/bash

logfile="../log.dat"
curr_stat_file="../curr.dat"
plot_short="../plot_short.dat"
plot_med="../plot_med.dat"
plot_long="../plot_long.dat"

num_samples_short=80
num_samples_med=200
num_samples_long=2000

function write_html() {
    local curr_state="$1"
    local state_num=`echo $curr_state | cut -d " " -f 2`

    local state_date=`echo $curr_state | cut -d " " -f 1 | sed 's/\(..\).\(..\).\(..\).\(..\).\(..\).\(..\)/20\3\1\2 \4\5/'`
    local state_sec=$(date +%s -d "$state_date")
    local state_time=`echo $curr_state | cut -d " " -f 1 | cut -d "-" -f 2`


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
            <span id="clock">&nbsp;</span>
        </div> 

        <script type="text/javascript">
        var start = new Date($state_sec * 1000).getTime()

        function tick() {
            var now = new Date().getTime()

            var s = parseInt((now - start) / 1000)
            var m = parseInt(s/60);
            var h = parseInt(m/60);

            s = s % 60;
            m = m % 60;

            var _s = (s < 10 ? "0" : "") + s
            var _m = (m < 10 ? "0" : "") + m

            var t = "(seit $state_time - " + h + " h, " + _m + " min, " + _s + " s)"
            document.getElementById("clock").firstChild.nodeValue = t
        }
        tick()
        setInterval('tick()', 1000)
        </script>


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
        <img src="../yesterday.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../before_yd.png?$RANDOM" /><br clear="all"><hr width="30%">
        
        <img src="../week.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../month.png?$RANDOM" />
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
    set xdata time
    set timefmt "%m/%d/%y-%H:%M:%S"
    set xrange [ "$from" : "$to" ]
    set yrange [ 0 : 4 ]
    set ytics 0,1
    set format y ""
    set ytics add ("schlaeft" 1)
    set ytics add ("wach" 2)
    set ytics add ("nuckelt" 3)
    set format x "%a %d\\n%H:%M"
    set grid
    set key left
    plot 'log.dat' using 1:2 index 0 t "" linecolor rgb "red" with lines, 'curr.dat' using 1:2 t "" linecolor rgb "red" with lines
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
    local ts="$2"
    local last_state="$3"

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


ts="`date +%D-%H:%M:%S`"
last_line=`tail -1 $logfile`
last_state=`echo $last_line | cut -d " " -f2`

if [ "$REQUEST_METHOD" = "POST" ] ; then
    data="$(</dev/stdin)"
    case "$data" in
        sleep*) add_log "1" "$ts" "$last_state";;
        awake*) add_log "2" "$ts" "$last_state";;
        feed*)  add_log "3" "$ts" "$last_state";;
    esac
else
    today="`date +%D-%H:%M:%S -d 0`"
    tomorrow="`date +%D-%H:%M:%S -d \"+1day 0\"`"
    echo "$last_line" > "$curr_stat_file"
    echo "$ts $last_state" >> "$curr_stat_file"

    ( cd ..; plot "$today" "$tomorrow" "today" "Heute" )
    write_html "$last_line"
fi
