#!/usr/bin/env bash
echo -e "\033[5;33;49m[DEPRECATED] ?? Please use source common_bash.sh instead\033[0m" >&2
#/bin/bash

###### color ######
COLOR_END='\033[0m'

## format codes:
format_none=0
format_bold=1
format_italic=3
format_underscore=4
format_blink=5
format_reverse=7
format_concealed=8

## foreground color codes:
fg_default=39
fg_black=30
fg_red=31
fg_green=32
fg_yellow=33
fg_blue=34
fg_magenta=35
fg_cyan=36
fg_light_grey=37
fg_dark_grey=90
fg_light_red=91
fg_light_green=92
fg_light_yellow=93
fg_light_blue=94
fg_light_magenta=95
fg_light_cyan=96
fg_white=97

## Background color codes:
bg_default=49
bg_black=40
bg_red=41
bg_green=42
bg_yellow=43
bg_blue=44
bg_magenta=45
bg_cyan=46
bg_light_grey=47
bg_dark_grey=100
bg_light_red=101
bg_light_green=102
bg_light_yellow=103
bg_light_blue=104
bg_light_magenta=105
bg_light_cyan=106
bg_white=107
###### color ######

COLOR_BLACK="\033[$format_none;$fg_black;$bg_default""m"
COLOR_RED="\033[$format_none;$fg_red;$bg_default""m"
COLOR_GREEN="\033[$format_none;$fg_green;$bg_default""m"
COLOR_BLUE="\033[$format_none;$fg_blue;$bg_default""m"
COLOR_YELLOW="\033[$format_none;$fg_yellow;$bg_default""m"
COLOR_MAGENTA="\033[$format_none;$fg_magenta;$bg_default""m"
COLOR_CYAN="\033[$format_none;$fg_cyan;$bg_default""m"
