#!/bin/bash

logfile="../log.dat"
plot_short="../plot_short.dat"
plot_med="../plot_med.dat"
plot_long="../plot_long.dat"

num_samples_short=80
num_samples_med=200
num_samples_long=2000

function write_html() {
    echo -en 'content-type:text/html; charset=utf-8\r\n\r\n'
    echo '
        <html>
        <head>

        <link rel="stylesheet" type="text/css" href="../index.css">

        </head>
        <body>
	<center>

        <div class="titlebar" height="15%">
            <h1 style="margin-left: 5pt;float:left;">Schnarch Tracker</h1>
            <h2 style="margin-left:7pt; padding-top:7pt; padding-right:10pt;
                       font-size:medium;float:right;">
               Version 0.1</h2>
            <br clear="all"/>
        </div> 

            <br clear="all"/>
                <h1 class="itemheader">Babystatus</h1>
            <br clear="all"/>

        <table style="margin-top:5pt; border:none;"> <tr>
            <td style="padding:5pt; vertical-align:top;">
                <form action="schlaeft" method="get" > 
                    <button class="button" type="submit">
                        schl&auml;ft </button> </form></td>
            <td style="padding:5pt; vertical-align:top;">
                <form action="wach" method="get" > 
                    <button class="button" type="submit"> 
                        ist wach </button> </form></td>
            <td style="padding:5pt; vertical-align:top;">
                <form action="nuckelt" method="get" > 
                    <button class="button" type="submit">
                        nuckelt </button> </form></td>
        </tr></table>

	</center>
        <br clear="all" />'
        
        echo "<img src=\"../history_short.png?$RANDOM\" /><br clear=\"all\"><hr width=\"30%\">"
        echo "<img src=\"../history_med.png?$RANDOM\" /><br clear=\"all\"><hr width=\"30%\">"
        echo "<img src=\"../history_long.png?$RANDOM\" /></body></html>"
}

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

function add_log() {
    local what="$1"
    local last_state=`tail -1 $logfile | cut -d " " -f2`
    local ts="`date +%D-%H:%M:%S`"

    if [ "$what" != "$last_state" ]; then
        echo "$ts $last_state" >> "$logfile"
        echo "$ts $what" >> "$logfile"
    fi

    # update plots
    tail -$num_samples_long "$logfile" > "$plot_long"
    tail -$num_samples_med "$plot_long" > "$plot_med"
    tail -$num_samples_short "$plot_med" > "$plot_short"
    ( cd ..; gnuplot plot_short.gnu >&2; gnuplot plot_med.gnu >&2; gnuplot plot_long.gnu >&2 )

    redirect
}

#
# MAIN
#

case `basename $0` in
    schlaeft*) add_log "1";;
    wach*)     add_log "2";;
    nuckelt*)  add_log "3";;
    *)         write_html;;
esac

