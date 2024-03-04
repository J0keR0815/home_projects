#!/bin/bash

# Check mode and default values
echo -e "########## Tests: Modes and default values ##########\n"

/bin/bash smart_check.sh test || echo "failed"
/bin/bash smart_check.sh test "" || echo "failed"
/bin/bash smart_check.sh test "L/.././../." && echo "ok"
/bin/bash smart_check.sh test "S/.././../." && echo "ok"
/bin/bash smart_check.sh test "l/.././../." || echo "failed"
/bin/bash smart_check.sh test "s/.././../." || echo "failed"
/bin/bash smart_check.sh test "/.././../." || echo "failed"
/bin/bash smart_check.sh test "/.././../." || echo "failed"
/bin/bash smart_check.sh test "X/.././../." || echo "failed"
/bin/bash smart_check.sh test "S//./../." || echo "failed"
/bin/bash smart_check.sh test "S/..//../." || echo "failed"
/bin/bash smart_check.sh test "S/.././/." || echo "failed"
/bin/bash smart_check.sh test "S/.././../" || echo "failed"
/bin/bash smart_check.sh test "S/.././.." || echo "failed"

echo -e "\n########## Tests done ##########\n"

echo -e "########## Tests: Month of year ##########\n"

# Single values
/bin/bash smart_check.sh test "L/,/./../." || echo "failed"
/bin/bash smart_check.sh test "L/;/./../." || echo "failed"
/bin/bash smart_check.sh test "L///./../." || echo "failed"
/bin/bash smart_check.sh test "L/-1/./../." || echo "failed"
/bin/bash smart_check.sh test "L/0/./../." || echo "failed"
/bin/bash smart_check.sh test "L/1/./../." || echo "failed"
/bin/bash smart_check.sh test "L/9/./../." || echo "failed"
/bin/bash smart_check.sh test "L/00/./../." || echo "failed"
/bin/bash smart_check.sh test "L/01/./../." || echo "failed"
/bin/bash smart_check.sh test "L/02/./../." || echo "failed"
/bin/bash smart_check.sh test "L/11/./../." || echo "failed"
/bin/bash smart_check.sh test "L/12/./../." || echo "failed"
/bin/bash smart_check.sh test "L/13/./../." || echo "failed"
/bin/bash smart_check.sh test "L/10/./../." && echo "ok"

# Groups
/bin/bash smart_check.sh test "L/()/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(())/./../." || echo "failed"
/bin/bash smart_check.sh test "L/()()/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(())/./../." || echo "failed"
/bin/bash smart_check.sh test "L/())/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(a)/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(a|)/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(a|))/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(a|)|b)/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(0|1|2)/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(00|01|02)/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(1|2)/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(01|02)/./../." || echo "failed"
/bin/bash smart_check.sh test "L/(01|02|10)/./../." && echo "ok"

# Ranges
/bin/bash smart_check.sh test "S/[]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[[]]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[][]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[[]-a]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[a-[]]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[01-[]]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[[]-01]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[10--]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[--10]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[00-01]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[01-01]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[01-01-]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[01-13]/./../." || echo "failed"
/bin/bash smart_check.sh test "S/[01-12]/./../." && echo "ok"
/bin/bash smart_check.sh test "S/[10-10]/./../." && echo "ok"
/bin/bash smart_check.sh test "S/[10-09]/./../." && echo "failed"

# Groups and ranges
/bin/bash smart_check.sh test "S/(01|[01-05]|11|[05-09])/./../." || \
    echo "failed"
/bin/bash smart_check.sh test "S/(01|[01-05]|11|[04-10])/./../." && \
    echo "ok"

echo -e "\n########## Tests done ##########\n"

echo -e "########## Tests: Week of month ##########\n"

# Single values
/bin/bash smart_check.sh test "L/../,/../." || echo "failed"
/bin/bash smart_check.sh test "L/../;/../." || echo "failed"
/bin/bash smart_check.sh test "L/..///../." || echo "failed"
/bin/bash smart_check.sh test "L/../-1/../." || echo "failed"
/bin/bash smart_check.sh test "L/../00/../." || echo "failed"
/bin/bash smart_check.sh test "L/../01/../." || echo "failed"
/bin/bash smart_check.sh test "L/../05/../." || echo "failed"
/bin/bash smart_check.sh test "L/../06/../." || echo "failed"
/bin/bash smart_check.sh test "L/../0/../." || echo "failed"
/bin/bash smart_check.sh test "L/../1/../." || echo "failed"
/bin/bash smart_check.sh test "L/../2/../." || echo "failed"
/bin/bash smart_check.sh test "L/../4/../." || echo "failed"
/bin/bash smart_check.sh test "L/../5/../." || echo "failed"
/bin/bash smart_check.sh test "L/../6/../." || echo "failed"
/bin/bash smart_check.sh test "L/../3/../." && echo "ok"

# Groups
/bin/bash smart_check.sh test "L/../()/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(())/../." || echo "failed"
/bin/bash smart_check.sh test "L/../()()/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(())/../." || echo "failed"
/bin/bash smart_check.sh test "L/../())/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(a)/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(a|)/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(a|))/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(a|)|b)/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(0|1|2)/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(00|01|02)/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(1|2)/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(01|02)/../." || echo "failed"
/bin/bash smart_check.sh test "L/../(1|2|3)/../." && echo "ok"

# Ranges
/bin/bash smart_check.sh test "L/../[]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[[]]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[][]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[[]-a]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[a-[]]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[01-[]]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[[]-1]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[3--]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[--3]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[0-1]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[1-1]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[1-1-]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[0-2]/../." || echo "failed"
/bin/bash smart_check.sh test "L/../[0-5]/../." && echo "ok"
/bin/bash smart_check.sh test "L/../[3-3]/../." && echo "ok"
/bin/bash smart_check.sh test "L/../[3-2]/../." && echo "failed"

# Groups and ranges
/bin/bash smart_check.sh test "L/../(0|[0-2]|4|[4-5])/../." || \
    echo "failed"
/bin/bash smart_check.sh test "L/../(0|[0-2]|4|[3-5])/../." && \
    echo "ok"

echo -e "\n########## Tests done ##########\n"

echo -e "########## Tests: Day of month ##########\n"

# Single values
/bin/bash smart_check.sh test "L/.././,/." || echo "failed"
/bin/bash smart_check.sh test "L/.././;/." || echo "failed"
/bin/bash smart_check.sh test "L/.././//." || echo "failed"
/bin/bash smart_check.sh test "L/.././-1/." || echo "failed"
/bin/bash smart_check.sh test "L/.././0/." || echo "failed"
/bin/bash smart_check.sh test "L/.././1/." || echo "failed"
/bin/bash smart_check.sh test "L/.././9/." || echo "failed"
/bin/bash smart_check.sh test "L/.././00/." || echo "failed"
/bin/bash smart_check.sh test "L/.././01/." || echo "failed"
/bin/bash smart_check.sh test "L/.././02/." || echo "failed"
/bin/bash smart_check.sh test "L/.././30/." || echo "failed"
/bin/bash smart_check.sh test "L/.././31/." || echo "failed"
/bin/bash smart_check.sh test "L/.././32/." || echo "failed"
/bin/bash smart_check.sh test "L/.././21/." && echo "ok"

# Groups
/bin/bash smart_check.sh test "S/.././()/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(())/." || echo "failed"
/bin/bash smart_check.sh test "S/.././()()/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(())/." || echo "failed"
/bin/bash smart_check.sh test "S/.././())/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(a)/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(a|)/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(a|))/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(a|)|b)/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(0|1|2)/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(00|01|02)/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(1|2)/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(01|02)/." || echo "failed"
/bin/bash smart_check.sh test "S/.././(01|02|21)/." && echo "ok"

# Ranges
/bin/bash smart_check.sh test "S/.././[]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[[]]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[][]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[[]-a]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[a-[]]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[01-[]]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[[]-01]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[21--]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[--21]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[00-01]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[01-01]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[01-01-]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[01-32]/." || echo "failed"
/bin/bash smart_check.sh test "S/.././[01-31]/." && echo "ok"
/bin/bash smart_check.sh test "S/.././[21-21]/." && echo "ok"
/bin/bash smart_check.sh test "S/.././[21-20]/." && echo "failed"

# Groups and ranges
/bin/bash smart_check.sh test "S/.././(01|[01-05]|20|[04-20])/." || \
	echo "failed"
/bin/bash smart_check.sh test "S/.././(01|[01-05]|20|[04-21])/." && \
    echo "ok"

echo -e "\n########## Tests done ##########\n"

echo -e "########## Tests: Day of week ##########\n"

# Single values
/bin/bash smart_check.sh test "S/.././../," || echo "failed"
/bin/bash smart_check.sh test "S/.././../;" || echo "failed"
/bin/bash smart_check.sh test "S/.././..//" || echo "failed"
/bin/bash smart_check.sh test "S/.././../-1" || echo "failed"
/bin/bash smart_check.sh test "S/.././../00" || echo "failed"
/bin/bash smart_check.sh test "S/.././../01" || echo "failed"
/bin/bash smart_check.sh test "S/.././../05" || echo "failed"
/bin/bash smart_check.sh test "S/.././../06" || echo "failed"
/bin/bash smart_check.sh test "S/.././../0" || echo "failed"
/bin/bash smart_check.sh test "S/.././../1" || echo "failed"
/bin/bash smart_check.sh test "S/.././../2" || echo "failed"
/bin/bash smart_check.sh test "S/.././../7" || echo "failed"
/bin/bash smart_check.sh test "S/.././../8" || echo "failed"
/bin/bash smart_check.sh test "S/.././../6" || echo "failed"

# Groups
/bin/bash smart_check.sh test "S/.././../()" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(())" || echo "failed"
/bin/bash smart_check.sh test "S/.././../()()" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(())" || echo "failed"
/bin/bash smart_check.sh test "S/.././../())" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(a)" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(a|)" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(a|))" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(a|)|b)" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(0|1|2)" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(00|01|02)" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(1|2)" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(01|02)" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(1|2|6)" && echo "ok"

# Ranges
/bin/bash smart_check.sh test "S/.././../[]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[[]]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[][]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[[]-a]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[a-[]]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[01-[]]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[[]-1]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[6--]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[--6]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[0-5]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[1-1]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[1-1-]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[1-5]" || echo "failed"
/bin/bash smart_check.sh test "S/.././../[1-7]" && echo "ok"
/bin/bash smart_check.sh test "S/.././../[6-6]" && echo "ok"
/bin/bash smart_check.sh test "S/.././../[6-2]" || echo "failed"

# Groups and ranges
/bin/bash smart_check.sh test "S/.././../(1|[1-2]|5|[4-5])" || echo "failed"
/bin/bash smart_check.sh test "S/.././../(1|[1-2]|5|[4-6])" && echo "ok"

echo -e "\n########## Tests done ##########\n"

echo -e "########## Tests: Conflicting values ##########\n"

/bin/bash smart_check.sh test "L/.././21/7" || echo "failed"
/bin/bash smart_check.sh test "L/.././20/6" || echo "failed"

echo -e "\n########## Tests done ##########\n"
