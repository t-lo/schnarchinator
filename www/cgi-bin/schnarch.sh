#!/bin/bash

# Files

logfile="../log.dat"
curr_stat_file="../curr.dat"
plot_short="../plot_short.dat"
plot_med="../plot_med.dat"
plot_long="../plot_long.dat"

function edit_diff() {
    local ts=`echo "$1" | sed 's/\//_/g'`
    echo "../edit-${ts}.diff"
}

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

        <br clear="all" />
        <img src="../today.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../yesterday.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../before_yd.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../before_yd2.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../before_yd3.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../before_yd4.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../before_yd5.png?$RANDOM" /><br clear="all"><hr width="30%">
        
        <img src="../week.png?$RANDOM" /><br clear="all"><hr width="30%">
        <img src="../month.png?$RANDOM" />

        <br clear="all" />
        <hr width="50%">
        <form action="schnarch.sh" method="post" > 
            <button class="button" name="edit" type="submit">
                Daten editieren</button> </form>
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
    local single_day="$3"
    local plot_name="$4"
    local desc="$5"

    local xtics=""
    local mxtics=""
    [    "$single_day" = "true" ] && {
        xtics="set xtics 0,7200"
      }

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
    set format x "%H:%M\\n%a %d"
    $xtics
    set mxtics 2
    set grid xtics mxtics ytics
    set key left
    plot 'log.dat' using 1:2 index 0 t "" \
        linecolor rgb "blue" with lines, \
    'curr.dat' using 1:2 t "" \
        linecolor rgb "blue" with lines
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
    local before_yd2="`date +%D-%H:%M:%S -d \"-3day 0\"`"
    local before_yd3="`date +%D-%H:%M:%S -d \"-4day 0\"`"
    local before_yd4="`date +%D-%H:%M:%S -d \"-5day 0\"`"
    local before_yd5="`date +%D-%H:%M:%S -d \"-6day 0\"`"

    local last_week="`date +%D-%H:%M:%S -d \"-7day 0\"`"
    local last_month="`date +%D-%H:%M:%S -d \"-30day 0\"`"

    (   cd ..;
        plot "$today" "$tomorrow" "true" "today" "Heute"
        plot "$yesterday" "$today" "true" "yesterday" "Gestern"
        plot "$before_yd" "$yesterday" "true" "before_yd" "Vorgestern"
        plot "$before_yd2" "$before_yd" "true" "before_yd2" "`date +%a -d-3day`"
        plot "$before_yd3" "$before_yd2" "true" "before_yd3" "`date +%a -d-4day`"
        plot "$before_yd4" "$before_yd3" "true" "before_yd4" "`date +%a -d-5day`"
        plot "$before_yd5" "$before_yd4" "true" "before_yd5" "`date +%a -d-6day`"

        plot "$last_week" "$tomorrow" "false" "week" "Letzte Woche"
        plot "$last_month" "$tomorrow" "false" "month" "Letzter Monat"
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

function edit_log() {
    echo -en 'content-type:text/html; charset=utf-8\r\n\r\n'
    echo '
    <html>
    <head>
        <link rel="stylesheet" type="text/css" href="../index.css">
    </head>
    <body>
	<center>
        <div class="titlebar" height="15%">
            <h1 style="margin-left: 5pt;">Status log editor </h1>
        </div> 

        <br clear="all"/>

        <form action="schnarch.sh" method="get" > 
            <button class="button" type="submit"> Abbrechen </button>
        </form>
        <br clear="all" />
        <hr width="50%" />
        <br clear="all" />
        <span>Event types: 1 - schl&auml;ft, 2 - wach, 3 - nuckelt <br />
              Timestamp format: mm/dd/yy-hh:mm:ss
        </span>
        <br clear="all" />
        <form action="schnarch.sh" method="post" > 
            <textarea rows="100" cols="40" name="post">'

    awk '1 == NR % 2' "$logfile"
   
    echo '  </textarea>
            <br clear="all" />
            <span>Event types: 1 - schl&auml;ft, 2 - wach, 3 - nuckelt <br />
                  Timestamp format: mm/dd/yy-hh:mm:ss
            <br clear="all" />
            <button class="button" type="submit">
                Speichern </button> </form>
    </center>
    </body></html>'
}
# ----

function urldecode(){
    echo -e "`sed 's/+/ /g; s/%/\\\x/g'`"
}
# ----

function post_log() {
    local diff_file=`edit_diff "$1"`
    local tmp=`mktemp`

    echo "$data" | cut -d '=' -f 2 | urldecode | sed 's/\r$//' | awk '{
        if (NF != 2) next
        if (oldstate) print $1 " " oldstate 
        print $1 " " $2
        oldstate=$2
    }' > $tmp

    diff --strip-trailing-cr "$logfile" "$tmp" > "$diff_file"
    mv "$tmp" "$logfile"

    generate_plots
    redirect
}
# ----

#
# MAIN
#
cd `dirname $0`

ts="`date +%D-%H:%M:%S`"
last_line=`tail -1 $logfile`
last_state=`echo $last_line | cut -d " " -f2`

if [ "$REQUEST_METHOD" = "POST" ] && [ "$CONTENT_LENGTH" -gt 0 ] ; then
    read -n $CONTENT_LENGTH -r data
    cmd=`echo "$data" | cut -d '=' -f 1`
    case "$cmd" in
        sleep) add_log "1" "$ts" "$last_state";;
        awake) add_log "2" "$ts" "$last_state";;
        feed)  add_log "3" "$ts" "$last_state";;
        edit)  edit_log;;
        post)  post_log "$ts";;
    esac
else
    today="`date +%D-%H:%M:%S -d 0`"
    tomorrow="`date +%D-%H:%M:%S -d \"+1day 0\"`"
    echo "$last_line" > "$curr_stat_file"
    echo "$ts $last_state" >> "$curr_stat_file"

    ( cd ..; plot "$today" "$tomorrow" "today" "Heute" )
    write_html "$last_line"
fi
