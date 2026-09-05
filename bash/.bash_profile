#
# ~/.bash_profile
#

case "$(tty)" in
	/dev/tty1)
		if uwsm check may-start; then
			exec uwsm start hyprland-uwsm.desktop
		fi
		;;
	/dev/tty3)
		exec ~/.local/bin/gamer-mode
		;;
esac
