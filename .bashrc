#echo "Bash $BASH_VERSION"

LS_OPTIONS='--color'
HISTCONTROL="ignoreboth:erasedups"
HISTIGNORE="l[sl]:[bf]g:exit:dir:cd:cd..:o:\..*:\+.*:\-.*"
HISTSIZE=2048
export HISTCONTROL HISTIGNORE HISTSIZE LS_OPTIONS

# Enable full path printing in screen
#LC_DIRMSG=True
# Enable full path printing before each prompt
#LC_DIRLINE=True

# Append history list instead of override
shopt -s histappend
# Force a reset of the readline library
unset TERMCAP
# Returns short path (last two directories)
spwd () {
	local _x
	eval _x=\"\$LC_DIRLINE\"
	if [ "$_x" == "" ]
	then (
		IFS=/
		_CWD="$(dirs +0)"
		set $_CWD
		if test $# -le 3
		then	echo "$_CWD"
		else
			_PFX="$1"
			_PFXNUM="$(($#-3))"
			eval _OFX=\${$(($#-1))}/\${$#}
			echo "$_PFX/<${_PFXNUM}<${_OFX}"
		fi
	);
	else	printf "\b"
	fi
}

# Set terminal titles
ttitle () {
	local _t="$1" _e _w _wx _ws _pn _p0 _p1 _p1k _p1n _p2 _p2n _p2x _p2xn _x _u="$USER" _h="$HOST"

	[ -z "$USER" ] && _u="$USERNAME"
	[ -z "$HOST" ] && _h="$HOSTNAME"

	# Grab terminal file
	[ -n "$_t" ] || return
	[ "${_t#tty}" = "$_t" ] && _t=pts/$_t
	[ -O /dev/$_t ] || return

	_e=0
	_w="$(dirs +0)"
	# Print complete path in a separate line
	eval _x=\"\$LC_DIRLINE\"
	[ "$_x" != "" ] && printf "CWD: $_w\n" > /dev/$_t

	_wx="$(echo "$_w" | awk -F/ '{print $NF}')"
	_p0="$(echo "$_w" | cut -d/ -f1)"
	_p1="$(echo "$_w" | cut -d/ -f2)"
	_p2="$(echo "$_w" | cut -d/ -f3-)"

	# Generate ultra short screen title
	if [ "$TERM" == "screen" ] || [[ "$TERM" = "screen-"* ]]
	then	# Prefix the shunk token
		_ws="$_p0"
		if [ "$_p1" != "$_p0" ]
		then	# Have second token
			if [ "$_p2" == "" ]
			then    # No third token, just a single directory name
				_pn=18
				if [ ${#_wx} -gt $_pn ]
				then    # Shink the first (and last) path token (sole directory name)
					_p1k=$(($_pn/2-2))
					_x=$((${#_wx}-$_p1k))
					_wt="$(echo "$_wx" | cut -b-${_p1k})...$(echo "$_wx" | cut -b${_x}-)"
				else    _wt="$_wx"
				fi
				_ws="${_ws}/${_wt}"
			else    # Have third token, need to count omitted levels
				_pn=15
				if [ ${#_wx} -gt $_pn ]
				then    # Shink the last path token (sole directory name)
					_p1k=$(($_pn/2-1))
					_x=$((${#_wx}-$_p1k+1))
					_wt="$(echo "$_wx" | cut -b-${_p1k})...$(echo "$_wx" | cut -b${_x}-)"
				else    _wt="$_wx"
				fi
				_ws="${_ws}/<$(echo "$_p2" | awk -F/ '{print NF}')<${_wt}"
			fi
		else	# No second token (root or home)
			[ "$_p0" == "" ] && _ws="/"
		fi
	fi

	# Generate terminal title
	if [ "$_p0" != "" -a "$_p0" != "~" ]
	then	# Unknown root token, do not process path
		printf "[?]"
	else	# Shrink path if it is too long
		_pn=60
		if [ ${#_w} -gt $_pn ]
		then	# Process the first path token
			_p1k=24
			if [ ${#_p1} -gt $_p1k ]
			then	# Shink the first path token (sole directory name)
				_p1k=$(($_p1k/2))
				_x=$((${#_p1}-$_p1k+4))
				_p1="$(echo "$_p1" | cut -b-${_p1k})...$(echo "$_p1" | cut -b${_x}-)"
			fi
			_p1n=${#_p1}
			_p2n=$(($_pn-$_p1n-1))

			# Process the second path token
			if [ ${#_p2} -gt $_p2n ]
			then	# Shink the second path token
				if [ "$(echo "${_p2}/" | cut -d/ -f2-)" = "" ]
				then	# Shink the sole directory name
					_p2xn=$(($_p2n/2-2))
					_x=$((${#_p2}-$_p2xn))
					_p2="$(echo "$_p2" | cut -b-${_p2xn})...$(echo "$_p2" | cut -b${_x}-)"
				else	# Shink a group of directory names
					_x=$((${#_p2}-$_p2n))
					_p2x="$(echo "$_p2" | cut -b${_x}- | cut -d/ -f2-)"
					# Check if the last directory name is shunk
					if [ "$(echo "${_p2x}/" | cut -d/ -f2-)" = "" ]
					then
						if [ "$_p2x" != "$_wx" -a ${#_wx} -gt $_p2n ]
						then	# Shink the sole directory name
							_p2xn=$(($_p2n/2-4))
							_x=$((${#_wx}-$_p2xn))
							_p2x="$(echo "$_wx" | cut -b-${_p2xn})...$(echo "$_wx" | cut -b${_x}-)"
						else	_p2x="$_wx"
						fi
					fi
					_p2=".../$_p2x"
				fi
			fi

			# Assemble shunk directory names
			_w="${_p0}/${_p1}/${_p2}"
		fi
	fi

	case "$TERM" in
		linux|*.linux)	# Don't do anything on a text console
		;;
		xterm)	printf "\e]2;%s@%s: %s\007" "$_u" "$_h" "$_w" > /dev/$_t
		;;
		screen|screen-*)
			printf "\eP\e]2;%s@%s: %s\007\e\\" "$_u" "$_h" "$_w"
			[ -z "$LC_CDISPATCH" ] && printf "\ek%s\e\\" "$_ws" > /dev/$_t
			# Put complete directory in message bar
			eval _x=\"\$LC_DIRMSG\"
			[ "$_x" != "" ] && printf "\e^CWD: $_w\e\\" > /dev/$_t
		;;
		*)	printf "[!]"
		;;
	esac
}

case "$TERM" in
	linux|*.linux|xterm|screen|screen-*)	_u="\[\e[1m\]\u\[\e[0m\]@\h"
	;;
	*)	_u="\u@\h"
	;;
esac

_t="\$(ttitle \l)"
_p=">"

# With full path on prompt
#PS1="${_t}${_u}:\w${_p} "
# With physical path even if reached over sym link
#PS1="${_t}${_u}:\$(pwd -P)${_p} "
# With short path on prompt
PS1="\[${_t}\]${_u}:\$(spwd)${_p} "

unset _u _p _t

PS2='> '

case "$TERM" in
	linux|*.linux)	# Don't do anything on a text console
	;;
	xterm)	printf "\e]1;Terminal on %s (%s)\007" "$HOST" "$USER"
	;;
	screen|screen-*)	printf "\eP\e]1;Terminal on %s (%s)\007\e\\" "$HOST" "$USER"
	;;
	*)	# Don't know how to set icon name
	;;
esac

function clear_bad_command {
	local exit_status=$?
	local cmdnumber=$(history | tail -n 1 | awk '{print $1}')
	if [ -n "$cmdnumber" ]; then
		if [ $exit_status -eq 127 ] && ([ -z $_lastcmd ] || [ $_lastcmd -lt $cmdnumber ]); then
			history -d $cmdnumber
		else
			_lastcmd=$cmdnumber
		fi
	fi
}

PROMPT_COMMAND="clear_bad_command"

# Access shared ssh agent
test -s $HOME/.sshagent && . $HOME/.sshagent

# Append user defined aliases
test -s $HOME/.alias && . $HOME/.alias

function svnk()
{
    rabbitvcs $*;
}

export gw=asds-172net-gw
export asds154=172.16.3.154
export asds185=172.16.3.185
export asds186=172.16.3.186
export asds187=172.16.3.187
export asds188=172.16.3.188
export asds189=172.16.3.189
export asds190=172.16.3.190

