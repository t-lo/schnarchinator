#!/bin/bash

logfile="log.dat"

function write_html() {
    echo -en '\r\n'
    echo '
        <html>
        <head>

        <link rel="stylesheet" type="text/css" href="../index.css">

        </head>
        <body>

        <div class="titlebar" height="15%">
            <h1 style="margin-left: 5pt;float:left;">Schnarch Tracker</h1>
            <h2 style="margin-left:7pt; padding-top:7pt; padding-right:10pt;
                       font-size:medium;float:right;">
               Version 0.1</h2>
            <br clear="all"/>
        </div> 

            <br clear="all"/>

        <table style="margin-top:5pt; border:none;"> <tr>
            <td style="padding:5pt; vertical-align:top;">
                <h1 class="itemheader">Babystatus</h1> </td>
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

        <br clear="all" />'
        
        echo "<img src=\"../history.png?$RANDOM\" /></body></html>"
}

function update_plot() {
    gnuplot plot.gnu 
}

function redirect() {
    echo -en '\r\n'
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
    local ts="`date +%D-%H:%M:%S`"

    echo "$ts $what" >> "$logfile"

    update_plot
    redirect
}

#
# MAIN
#

set -x

case `basename $0` in
    schlaeft*) add_log "1";;
    wach*)     add_log "2";;
    nuckelt*)  add_log "3";;
    *)         write_html;;
esac

