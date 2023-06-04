#!/bin/bash

car=("        "
	 "   TT   " 
	 " []||[] " 
	 "   )(   " 
	 "  |()|  " 
	 "[]\__/[]" 
	 "  \"  \"  "
	 "        ")

tree=("    "
      "_\/_"
      "/o\\\\"
      " |  "
      " |  "
      "    ")

enemy=("        "
	   " |\"‾‾\"| "
	   "[|####|]"
	   " |    | "
	   " |    | "
	   "[|\e[4m----\e[0m|]"
	   "        ")

hole=("    "
      "./#_"
      ")##<"
      "\"/* ")


function quit () {
    clear
    tput cnorm
    stty echo
    exit 0
}

# Проверяет размеры терминала
function check_term () {
    MIN_COL=68
    MIN_LINE=30

    if [[ ${1} -lt $MIN_COL ]] || [[ ${2} -lt $MIN_LINE ]] ; then
        echo "Please resize your terminal to at least ${MIN_COL}x${MIN_LINE}"
        exit 1
    fi
}

function printxy () { printf "\033[${2};${1}f${3}" ; }

function print_road {
	local x
	local y
	for ((i=2; i<=$SCREEN_BOTTOM; i++)) ; do
		for ((j=0; j<=NUMBER_OF_LANES*LANE_SIZE; j += $LANE_SIZE - 1)) ; do
			x=$(($j + $MID_X - $ROAD_WIDTH / 2))
			y=$i
			printxy $x $y "\e[2m|\e[0m"
		done
	done
}

function print_car () {
	local y
	for ((i=0; i<${#car[@]}; i++)); do
		y=$((${2} + $i ))
		printxy ${1} $y "${car[$i]}"
	done
}

function erase_car () {
	local y
	for ((i=0; i<${#car[@]}; i++)); do
		y=$((${2} + $i ))
		printxy ${1} $y "        "
	done
}

function print_enemy () {
	local y
	for (( i=0; i<${#enemy[@]}; i++ )); do
		y=$((${2} + $i ))
		if [[ $y -ge 2 ]] && [[ $y -le $SCREEN_BOTTOM ]]; then
			printxy ${1} $y "${enemy[$i]}"
		fi
	done
}

function print_tree () {
	local newy
	if [[ ${2} -ge -5 ]]; then
		for (( i=0; i<${#tree[@]}; i++ )); do
			newy=$((${2} + $i ))
			if [[ $newy -ge 2 ]] && [[ $newy -le $SCREEN_BOTTOM ]]; then
				printxy ${1} $newy "${tree[$i]}"
			fi
		done
	fi
}

function print_hole () {
	local newy
	if [[ ${2} -ge -3 ]]; then
		for (( i=0; i<${#hole[@]}; i++ )); do
			newy=$((${2} + $i ))
			if [[ $newy -ge 2 ]] && [[ $newy -le $SCREEN_BOTTOM ]]; then
				printxy ${1} $newy "${hole[$i]}"
			fi
		done
	fi
}

function trees_update {
	for ((i=0; i<${#trees[@]}; i++)); do
		trees[$i]=$((${trees[$i]} + 1))
		if [[ ${trees[$i]} -gt $SCREEN_BOTTOM ]]; then
			trees[$i]=$((${#tree[@]}*(-1)))
		fi
	done
}

function enemy_update {
	ENEMY_Y=$(($ENEMY_Y + 1))
	if [[ $ENEMY_Y -gt $SCREEN_BOTTOM ]]; then
		SCORE=$(($SCORE+1))
		ENEMY_Y=-7
		ENEMY_X=$((RANDOM % 5 * ($LANE_SIZE - 1) + $LEFT_LANE_X))
	fi
}

function hole_update {
	HOLE_Y=$(($HOLE_Y + 1))
	if [[ $HOLE_Y -gt $SCREEN_BOTTOM ]]; then
		spawn_hole
	fi
}

function score_print {
	printxy $(($MID_X - 6)) $TERM_LINE "Обогнал: $SCORE"
}

function check_collision {
	if [[ $X -eq $ENEMY_X ]] && [[ $(($Y - $ENEMY_Y)) -le 4 ]] && [[ $(($Y - $ENEMY_Y)) -ge -5 ]]; then
		quit
	fi
	if [[ $X -eq $(($HOLE_X - 2)) ]] && [[ $(($Y - $HOLE_Y)) -le 2 ]] && [[ $(($Y - $HOLE_Y)) -ge -5 ]]; then
		quit
	fi
}

function spawn_hole {
	HOLE_X=$((RANDOM % 5 * ($LANE_SIZE - 1) + $LEFT_LANE_X + 2))
	while [ $HOLE_X -eq $(($ENEMY_X + 2)) ]; do
		HOLE_X=$((RANDOM % 5 * ($LANE_SIZE - 1) + $LEFT_LANE_X + 2))
	done
	HOLE_Y=$((0 - RANDOM % 30))
}

# Размеры терминала
TERM_COL=$(tput cols)
TERM_LINE=$(tput lines)

# Проверяем на соответствие
check_term $TERM_COL $TERM_LINE

trap quit INT TERM SIGINT SIGTERM EXIT
trap '' SIGWINCH
clear

# Отключаем ввод и курсор
stty -echo
tput civis

# Границы окна внутри рамки
SCREEN_TOP=2
SCREEN_BOTTOM=$(($TERM_LINE-2))
SCREEN_LEFT=2
SCREEN_RIGHT=$(($TERM_COL-1))

# Отрисовка рамки
for ((i=$SCREEN_LEFT; i<=$SCREEN_RIGHT; i++ )); do
	printxy $i 1 "\e[2m═\e[0m"
	printxy $i $(($TERM_LINE-1)) "\e[2m═\e[0m"
done

for ((i=$SCREEN_TOP; i<=$SCREEN_BOTTOM; i++ )); do
	printxy 1 $i "\e[2m║\e[0m"
	printxy $TERM_COL $i "\e[2m║\e[0m"
done

printxy 1 1 "\e[2m╔\e[0m"
printxy $TERM_COL 1 "\e[2m╗\e[0m"
printxy 1 $(($TERM_LINE-1)) "\e[2m╚\e[0m"
printxy $TERM_COL $(($TERM_LINE-1)) "\e[2m╝\e[0m"


MID_X=$(($TERM_COL / 2))

LANE_SIZE=12
NUMBER_OF_LANES=5

ROAD_WIDTH=$(( ($LANE_SIZE-1)*$NUMBER_OF_LANES + 1 ))
LEFT_LANE_X=$(($MID_X - $ROAD_WIDTH / 2 + 2))
RIGHT_LANE_X=$(($LEFT_LANE_X + ($LANE_SIZE-1)*($NUMBER_OF_LANES-1)))

TREE_WIDTH=4
LEFT_TREE_X=$(($LEFT_LANE_X - 2 - 1 - $TREE_WIDTH))
RIGHT_TREE_X=$(($RIGHT_LANE_X - 2 + $LANE_SIZE + 1))
trees=(0 -20)

ENEMY_X=$((RANDOM % 5 * ($LANE_SIZE - 1) + $LEFT_LANE_X))
ENEMY_Y=-7

HOLE_X=0
HOLE_Y=0
spawn_hole

CAR_HEIGHT=${#car[@]}
X=$LEFT_LANE_X
Y=$(($SCREEN_BOTTOM -$CAR_HEIGHT))

# Массивы скоростей движения для разных уровней сложности
# Чем больше индекс, тем выше сложность
MY_SPEED=(12 10 8 6 4 4 3)
ENEMY_SPEED=(40 32 24 16 10 8)

TREE_TICK=0
ENEMY_TICK=0

DIFFICULTY=0

SCORE=0

while true; do

	read -t0.001 -n1 input;
	case $input in
		"w") ((Y--)); [[ $Y -le 5 ]] && Y=5 ;;
		"a") [[ $X -ne $LEFT_LANE_X ]] && erase_car $X $Y; ((X-=LANE_SIZE-1)); [[ $X -le $LEFT_LANE_X ]] && X=$LEFT_LANE_X ;;
		"s") ((Y++)); [[ $Y -ge $(($SCREEN_BOTTOM - $CAR_HEIGHT + 1)) ]] && Y=$(($SCREEN_BOTTOM - $CAR_HEIGHT + 1)) ;;
		"d") [[ $X -ne $RIGHT_LANE_X ]] && erase_car $X $Y; ((X+=LANE_SIZE-1)); [[ $X -ge $RIGHT_LANE_X ]] && X=$RIGHT_LANE_X ;;
	esac

	TREE_TICK=$(($TREE_TICK + 1))
	ENEMY_TICK=$(($ENEMY_TICK + 1))

	if [[ $TREE_TICK -ge ${MY_SPEED[$DIFFICULTY]} ]]; then
		TREE_TICK=0
		trees_update 
		hole_update
	fi

	if [[ $ENEMY_TICK -ge ${ENEMY_SPEED[$DIFFICULTY]} ]]; then
		ENEMY_TICK=0
		enemy_update
	fi

	if [[ $SCORE -ge 1 ]]; then
		DIFFICULTY=1
	fi
	if [[ $SCORE -ge 4 ]]; then
		DIFFICULTY=2
	fi
	if [[ $SCORE -ge 8 ]]; then
		DIFFICULTY=3
	fi
	if [[ $SCORE -ge 12 ]]; then
		DIFFICULTY=4
	fi
	if [[ $SCORE -ge 20 ]]; then
		DIFFICULTY=5
	fi
	if [[ $SCORE -ge 50 ]]; then
		DIFFICULTY=6
	fi

	check_collision

	print_road
	print_hole $HOLE_X $HOLE_Y
	print_car $X $Y
	print_enemy $ENEMY_X $ENEMY_Y
	print_tree $LEFT_TREE_X ${trees[0]}
	print_tree $RIGHT_TREE_X ${trees[1]}
	score_print

done