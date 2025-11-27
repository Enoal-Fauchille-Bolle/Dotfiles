#!/bin/bash

############################## Configuration ##############################

executables="amazed"
allowed_functions="read, write, malloc, free, getline"
ncurses_functions="addch, addchnstr, addchstr, addnstr, addstr, attroff, attron, attrset, attr_get, attr_off, attr_on, attr_set, baudrate, beep, bkgd, bkgdset, border, box, can_change_color, cbreak, chgat, clear, clearok, clrtobot, clrtoeol, color_content, color_set, COLOR_PAIR, copywin, curs_set, def_prog_mode, def_shell_mode, delay_output, delch, delscreen, delwin, deleteln, derwin, doupdate, dupwin, echo, echochar, erase, endwin, erasechar, filter, flash, flushinp, getbkgd, getch, getnstr, getstr, getwin, halfdelay, has_colors, has_ic, has_il, hline, idcok, idlok, immedok, inch, inchnstr, inchstr, initscr, init_color, init_pair, innstr, insch, insdelln, insertln, insnstr, insstr, instr, intrflush, isendwin, is_linetouched, is_wintouched, keyname, keypad, killchar, leaveok, longname, meta, move, mvaddch, mvaddchnstr, mvaddchstr, mvaddnstr, mvaddstr, mvchgat, mvcur, mvdelch, mvderwin, mvgetch, mvgetnstr, mvgetstr, mvhline, mvinch, mvinchnstr, mvinchstr, mvinnstr, mvinsch, mvinsnstr, mvinsstr, mvinstr, mvprintw, mvscanw, mvvline, mvwaddch, mvwaddchnstr, mvwaddchstr, mvwaddnstr, mvwaddstr, mvwchgat, mvwdelch, mvwgetch, mvwgetnstr, mvwgetstr, mvwhline, mvwin, mvwinch, mvwinchnstr, mvwinchstr, mvwinnstr, mvwinsch, mvwinsnstr, mvwinsstr, mvwinstr, mvwprintw, mvwscanw, mvwvline, napms, newpad, newterm, newwin, nl, nocbreak, nodelay, noecho, nonl, noqiflush, noraw, notimeout, overlay, overwrite, pair_content, PAIR_NUMBER, pechochar, pnoutrefresh, prefresh, printw, putwin, qiflush, raw, redrawwin, refresh, resetty, reset_prog_mode, reset_shell_mode, ripoffline, savetty, scanw, scr_dump, scr_init, scrl, scroll, scrollok, scr_restore, scr_set, setscrreg, set_term, slk_attroff, slk_attr_off, slk_attron, slk_attr_on, slk_attrset, slk_attr, slk_attr_set, slk_clear, slk_color, slk_init, slk_label, slk_noutrefresh, slk_refresh, slk_restore, slk_set, slk_touch, standout, standend, start_color, subpad, subwin, syncok, termattrs, termname, timeout, touchline, touchwin, typeahead, ungetch, untouchwin, use_env, use_tioctl, vidattr, vidputs, vline, vwprintw, vw_printw, vwscanw, vw_scanw, waddch, waddchnstr, waddchstr, waddnstr, waddstr, wattron, wattroff, wattrset, wattr_get, wattr_on, wattr_off, wattr_set, wbkgd, wbkgdset, wborder, wchgat, wclear, wclrtobot, wclrtoeol, wcolor_set, wcursyncup, wdelch, wdeleteln, wechochar, werase, wgetch, wgetnstr, wgetstr, whline, winch, winchnstr, winchstr, winnstr, winsch, winsdelln, winsertln, winsnstr, winsstr, winstr, wmove, wnoutrefresh, wprintw, wredrawln, wrefresh, wscanw, wscrl, wsetscrreg, wstandout, wstandend, wsyncdown, wsyncup, wtimeout, wtouchln, wvline"
math_functions="acos, acosh, asin, asinh, atan, atan2, atanh, cbrt, ceil, copysign, cos, cosh, cospi, cyl_bessel_i0, cyl_bessel_i1, erf, erfc, erfcinv, erfcx, erfinv, exp, exp10, exp2, expm1, fabs, fdim, floor, fma, fmax, fmin, fmod, frexp, hypot, ilogb, j0, j1, jn, ldexp, lgamma, long, long, log, log10, log1p, log2, logb, lrint, lround, modf, nan, nearbyint, nextafter, norm, norm3d, norm4d, normcdf, normcdfinv, pow, powi, rcbrt, remainder, remquo, rhypot, rint, rnorm, rnorm3d, rnorm4d, round, rsqrt, scalbln, scalbn, sin, sincos, sincospi, sinh, sinpi, sqrt, tan, tanh, tgamma, trunc, y0, y1, yn"

################################# Script ##################################

# Setting up the list of executables
executables_list=()
IFS=',' read -ra elements <<< "$executables"
for element in "${elements[@]}"; do
    element=$(echo "$element" | xargs | tr '[:upper:]' '[:lower:]')
    if [[ "$element" == "" ]]; then
        continue
    fi
    if [[ ! -x "$element" ]]; then
        echo "Executable '$element' does not exist or is not executable."
        echo "::error file=${element},title=Executable does not exist or is not executable::Executable '$element' does not exist or is not executable."
        exit 1
    fi
    executables_list+=("$element")
done

# Setting up the list of banned functions
allowed_functions_list=()
IFS=',' read -ra elements <<< "$allowed_functions"
for element in "${elements[@]}"; do
    element="$(echo "$element" | xargs | tr '[:upper:]' '[:lower:]')"
    if [[ "$element" == "" ]]; then
        continue
    fi
    allowed_functions_list+=("$element")
done

# Setting up the list of ncurses functions
ncurses_functions_list=()
IFS=',' read -ra elements <<< "$ncurses_functions"
for element in "${elements[@]}"; do
    element="$(echo "$element" | xargs)"
    if [[ "$element" == "" ]]; then
        continue
    fi
    ncurses_functions_list+=("$element")
done

# Setting up the list of math functions
math_functions_list=()
IFS=',' read -ra elements <<< "$math_functions"
for element in "${elements[@]}"; do
    element="$(echo "$element" | xargs)"
    if [[ "$element" == "" ]]; then
        continue
    fi
    math_functions_list+=("$element")
done

# Function to check if a function is banned
is_allowed() {
    local function_name=$1
    local source_name=$2
    for allowed_function in "${allowed_functions_list[@]}"; do
        # echo "$allowed_function"
        if [[ "$function_name" == "$allowed_function" ]] || [[ "$source_name" == "$allowed_function" ]]; then
            return 1
        fi
        if [[ $(echo "$allowed_function" | tr '[:upper:]' '[:lower:]') == "ncurses" ]]; then
            for ncurses_function in "${ncurses_functions_list[@]}"; do
                if [ "$function_name" == "$ncurses_function" ]; then
                    return 1
                fi
            done
        fi
        if [[ $(echo "$allowed_function" | tr '[:upper:]' '[:lower:]') == "math" ]]; then
            for math_function in "${math_functions_list[@]}"; do
                if [ "$function_name" == "$math_function" ]; then
                    return 1
                fi
            done
        fi
        if [[ $(echo "$allowed_function" | tr '[:upper:]' '[:lower:]') == "csfml" ]] && [[ "$function_name" == sf* ]]; then
            return 1
        fi
    done
    return 0
}

# Parsing executables
for executable in "${executables_list[@]}"; do
    nm $executable -u | while IFS= read -r line; do
        info=$(echo "$line" | xargs | cut -d ' ' -f 2)
        function_name=$(echo "$info" | cut -d '@' -f 1)
        source=$(echo "$info" | cut -d '@' -f 2)
        source_name=$(echo "$source" | cut -d '_' -f 1 | tr '[:upper:]' '[:lower:]')
        source_version=$(echo "$source" | cut -d '_' -f 2)
        if [[ "$info" == "__gmon_start__" ]] || [[ "$function_name" == "__libc_start_main" ]]; then
            continue
        fi
        if is_allowed "$function_name" "$source_name" == 0; then
            echo "::error file=${executable},title=Function is not allowed::'$function_name' is not allowed"
            exit 1
        fi
    done
done
