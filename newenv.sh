#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="3783453241"
MD5="ad81ee61bb6b1a47ad896c555cccce9c"
TMPROOT=${TMPDIR:=/tmp}

label="Newenv package"
script="./init.sh"
scriptargs=""
licensetxt=""
targetdir="/var/lib/newenv"
filesizes="5319"
keep="y"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo $licensetxt
    while true
    do
      MS_Printf "Please type y to accept, n otherwise: "
      read yn
      if test x"$yn" = xn; then
        keep=n
 	eval $finish; exit 1        
        break;    
      elif test x"$yn" = xy; then
        break;
      fi
    done
  fi
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test "$noprogress" = "y"; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd bs=$offset count=0 skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.2.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
 
 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
    PATH="$OLD_PATH"

    if test "$quiet" = "n";then
    	MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 500 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test `basename $MD5_PATH` = digest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test $md5 = "00000000000000000000000000000000"; then
				test x$verb = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test "$md5sum" != "$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x$verb = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test $crc = "0000000000"; then
			test x$verb = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test "$sum1" = "$crc"; then
				test x$verb = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test "$quiet" = "n";then
    	echo " All good."
    fi
}

UnTAR()
{
    if test "$quiet" = "n"; then
    	tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

    	tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 60 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 22 10:33:02 EET 2016
	echo Built with Makeself version 2.2.0 on 
	echo Build command was: "/home/user/work/makeself-2.2.0/makeself.sh \\
    \"--target\" \\
    \"/var/lib/newenv\" \\
    \"/home/user/work/env_common/build/\" \\
    \"newenv.sh\" \\
    \"Newenv package\" \\
    \"./init.sh\""
	if test x$script != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"/var/lib/newenv\"
	echo KEEP=y
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=60
	echo OLDSKIP=501
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 500 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 500 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - $*
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	finish="echo Press Return to close this window...; read junk"
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test "$quiet" = "y" -a "$verbose" = "y";then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

MS_PrintLicense

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test "$nox11" = "n"; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm rxvt dtterm eterm Eterm kvt konsole aterm"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test "$targetdir" = "."; then
    tmpdir="."
else
    if test "$keep" = y; then
	if test "$quiet" = "n";then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x$SETUP_NOCHECK != x1; then
    MS_Check "$0"
fi
offset=`head -n 500 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 60 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test "$quiet" = "n";then
	MS_Printf "Uncompressing $label"
fi
res=3
if test "$keep" = n; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 60; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (60 KB)" >&2
        if test "$keep" = n; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; UnTAR x ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test "$quiet" = "n";then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = xy; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval $script $scriptargs $*; res=$?;
		fi
    else
		eval $script $scriptargs $*; res=$?
    fi
    if test $res -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test "$keep" = n; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
‹ ¾4Xí<û{ÚF¶ù5ú+NdZ ùÄËÆô:!-µ‰Ë®¾`7›‹Y*Kô$Ev¼±÷o¿çÌŒÈÓ&n÷[MÚÍœ9¯9¯¹R}òÍ[[«Ù¤Ïz«Y‹íI}»Vob£¹ƒı­V£öšO¡­=_uğÓpïwÿóÿĞV©z®V}ù·Z“c÷I­^kÖ¹üOş–qeX—oñ§È¿Yo1ùï4w·wv(ÿÆvkç	Ôrùó¶õ¬zaZÕÕ[H[o†ƒşé>ş?u‡’g¯]Í€B¿û¶ÛÿuŠOŞ}³µ¥ù¦my¨4’´öÔ¹Ñ–Ïèc¸6ÁX³W+ÕÒ'0Vİ¹7‘¤ıÁñq§0Ú“$ U×7Í5Tß i Ù–¯š–áBÉ´@[»®aù ›.\\ƒnÌÔõÒ/W`dPËEYKŠ0³]† –.Ğf|‰‘±44ØÓÂgÌ9\ª®©^,/	“M@c ‹’,I[Ã³>g§È Gu=c*è„ÂOÒèşKóÑ÷ÿnk[ìÿVkw·Eöÿåûÿ±÷B›KeøD[HõuLK¢„Û­,ñMU;}Š}¨88ìÓO{[Y<öæÌß_¾d_”ÅßU„¡-lœÅ¬Ÿe|4ù16".F]«Ek‰‰ÏËà¸¦åÏ@6—Kc®.A¶ßyç–Ì‰zı}c“¨±zÖğTMº•£LUÇÒŒRù“”bÓ½t>M9V•MßŒ;ÊÿM—¥§½şè´Óßï¶ué)§ë)˜AR€ÂMO7	z*¨!`Œˆbé¤B1ƒ„Çèõ÷Îº™2RÌös>Ç3Ğ‚›P¬&gUµódG»H2ßzŞ¾•“>)¶°xµ`ÿfKuş»x²Îv˜İd»…<z:dÎş‰pĞmZ^°…»HÑxşğEñÆ§wbãW4ş—Áèô 7|ÀğE0¼sÔëŒ0A-Cçì”&OÛõ;Í	ê!ú¾“ÏCÄ‘ááˆh#db¬ÔmË ~2ì®@€-dÜr	W¦¿ Eg¯<E8'G»EL©€b¦ŸU ^¹ 8 w\®í5xk×øÆ×Õşdá9(<ƒ›.¥ /µñõ»ÉØèNÆŞhrC?Ê>£æ»k#Ñ!˜À‘x2S—^æØ@¯Œ†¶öcv8Ã»k‹CÔ.”°+DÓXÎbºeøW¶û>=_t?Æ7°®Ü$"”%ßY£¸1ğº€V9ösõrAàtÏ]¨•qYiØ¶@ãõ÷õß¤îp8"‘>J†0æ®áñ‘×µİRÂ¥©ù7k‹ÂÂ×ø°6Q%cx†S$&ğı÷…ìe?ÜÜ@€A’œ[{!/CaÎÅ*çr‚Ì–d<+³ı²04—˜§øÈó=®.:èx¸±1™KßpÛ²¥®Œ6	Fù€´¤¨<‚ÄçàPƒÃ z•àğêAøˆ(G2õhîÅÚ\rM+›+µ‡“q©h˜Ğ±¢–^(ùÅ¹÷¢DTÆ/2Íg$·ç¤€Â³å|(4Ø”Ø†È˜€OQì8¥AÒøÔÈ˜ *òEñÖØ…ÒÜ@	`ß”÷”˜ªëª×Œ¼È´-m4m(~ã=3”ÈËØãÏLKXar*˜¼¬0z)ü	kæÆc(ˆGĞnCAÀƒÉä%øÃJXXKt\ ïÃ™É¾2cÌ§¿v-( ¹A:æ†O˜)C¤Ñ¡4‹ä  â+Õ‡â§O®jÍ¨ôN:Ç•}–wİŞ~úT1@ôÕ°ôÛÛ"Û«Áj¦ÃfÅuêa«ìÂc‹ôN.w:º[CÆR	ÁÑrÇ^::û¹ß=E‹qÇÚ®©ÏßEå¦µ>(zwW]i”¥î?z£ÓîÁ|;ş}t÷ªpÓ(Ê¿nú.¡øÏBV,š)•Àl×^š¯ÍÆKóÅ(—_2ù#ìYŒiğj•ZÁ$óz¡‘û(”Rû  FÒ¤—ÉÆÑ0ÓZ¡¡Ãå
Â­Öw#CXƒ‡P¦Ã5“°7
Å
%Ïø@–LØÒvM«3*S9Åƒírå;Ø€´—iëq—Ï÷İ3Ü´ÿÿ×”ÿ™¼8¯dØf”²íø4ôyO
fpÆtdF"GRìÂîÖ 7‚pE’˜ÿ'ò¸GÎÿëµV­ÔkÍİm–ÿïîæùÿcçÿ™U<*¯ƒœtãÁÉioĞá7
ï'’ô¬?8íîUÅ‚ú¼ád8ø[wÿ0câç`øŞşÒváİàŞvú§p:€ÎÁPÅíGwÁ:[álÔÅ¾]­—Ë©£b.@I/fŒÏ$iŸ1y¼déĞE€Ş.ıƒŸ ÀÒ¼pU÷ÄRÇ±,»ˆâ@#Z8ìÿ½;|Ó;ê$NÜ;L4ÕÂ¥µåZg©.seĞî¬%iÀ3Ä=JyÕ¸^©Ì[Gx“&2rRŞ5’¹âk‡*¦˜4^ªKÜıÀ=´³T5.r $ŒÜkÇÆJ4-”1¤joĞT®lä’iq7‚èØ –8ApÅ8:² FÈ¯(ÃpÇU'I º4U|¶çñ»\@c6mm>†ÁZÅaäùÒ1xƒVßõJœ{P©–7è
¡÷DÃI1²ÓÌ3JB×_˜°•7 ‘S±/1L7uƒåŸ˜]{íôÎ„a=c=àƒ\(zèyq
_›pèĞoIê`PNº¨±>¢˜'ÃÈW²]”(;¾D¤tV&dîV‰‹Ùø¨®ÔrL‰¨ıPÛû¡VÉ¿Gê¼)|INÕ¾x¡#Q
‰
s½ãÎa·ß9î¶İş¯òT.„ÛrŒ£D5C$SôkzÒ9ı¥{‚n.Ş/j>h†¬KI+I8¼<Q(¡¶ŒÃ_–B[Ó³âXı|Ö;:˜² „¢°XnƒPBjnèÚ²¢°èÁöƒd©pM/DvGa¸"S§(d*g}VÒ)ß("‹a\•ïª–{áP™±Qà"È0{Ñ–Ù¡Ç±Id»3fğşP:¬x”	˜60§(ÇE¤Ìi†“9ƒµµÄ€\ñ|w°.c ²õ¦³:’îJ©qû¬ò3S5ß«T*©ÜXzCım™}ìQ) Ñ	D˜N’cr(ß—Ê×Ë‘Ñè,—TPºb/ã®4]¢X‘)h\±1/EvÆcI9@3ÊÀ!U@­†ÒGø“p>pO5%W•Ú#e2ü,ì¼sÍ˜ßK-H4e¬•9*},›ä¤§§É÷3<æŠ-}„½¶tŠâuÓu1²]Ó ñûñÅãÛƒ=»‹	wI
$Ä8P¡ûèQƒ©“ã†%!…ä4º¤ hŠY$æ\ÕvB;r.l.’ }Œh’ xÕAß;÷Ïı8èxàk¯â¡Ìù&óù’HkŠÔPÍ÷8(ÚÚáB¡ŸËP:ó04,^®HÎ\[PRæ3W(0_WÀ}Ö,sÕc¼$\! E¿ß0Fû*I]JÃ:§§İ>yÅ=8&dQR"ü<ªV+Ç¿FzÑ&,½PL®qåšôÜJ*q]èQd±_Ş¡BAÖfş/›ÊAc[ ‚HS (š”„„ á.­|§÷ù8R˜HåƒÉJÏ€±![ãàHùÓ õOC‹ˆ{¬»KYğÉtğLšAq×–¿oû¨ÉıD2,A2ÕZ]û6÷‚gñ ÿÂ¶}¾ +¤3­Şğ8<Ğ«™ö#‘6l:EªğÊ€´ÅŒWä‘ÁMdKÊ1ÚZ‹/%Š³°atâà7
öTú‚ùÌ­~D´> ÕÄ|-ğ4u›ºzN'…Rê¼R“ØàpÍÚ¬ü³9ÁñCä~Êı­PõîSéE·±zWÑÖÜádÏØáKíE2æUÄ¯ò£ˆ”	#B"~C*´#Dz'2'dxÖ—îd0å‘H#{8b‡,ß”Ñei‹
ıVK¬Šh‡Jw€Ê"D	¥‹2QV¬jçìÄƒŞb117,Ìm„×¯#%ç=Yå#(¿`ê [ŞJõ>H™;üĞ¶)³3`¯œr*)ñ=¼ş'®V<öıßİV“Õÿ¶wë­zƒîÿmo·yıï/QÿcÅ¬1]”˜TÙü&.uùU>Ü%¢ıŞÒæ{†êj‹ğ¦JFİ‚(Æ7ÑÉÅ‹jT08¥z-,ªo”z¢¥+2HAUÍ™XPõå^B³Jñî+Œ6æ¯a^qzê øREt#€)
x‰*¬å%#I^VZ˜¾¶ˆ MÃœ—^3VÒ‘d)v•¥¤.<İÍ%9È±û:_é¶a¥jZ¦ÿ­nş>èş_£Õªóû»øßÎîÿz£™ßÿ{üû¿UÚPSß’NŠ!Å4²ıî^÷)Q5diZïÙ%Zù7)VkË\k¿H·ÅSô‰‘b+9y[°}ˆ[*¸iÀ·4¯ÊHAø'BåR|º¶vÑçz£#Xø¾ãíU«sÃ¯ğ1ˆÆ
nÀ[ë¸çáJkN­¤:¾‚s!DGŒR®%ß^ã¾/DôHšêÃk¨¾Vã*z@vÀ«W4
ã1‹“ÙO6Ñ²¸34FmgMÚB‘éJØïI4,WHSÛ¬°Ïb¢j*'q ¾KŞÒÀ ¨.â‘ 	zÆ¥‰F/ e.È›•ú>¸D-¨‹ßÈC‚ØÅ<ü½¡
LâN(N[)VâIªš{)K%Ø•º3(ËRXd•«Ä]Yb¸	ˆK@º"¢a¡V¬DO7èr…£zŞ•qÜHœºqYµÖÈ4v› Ê>~”ƒ6¼‡A«°‹êÇI(Šâ-„À6ap5Œ¯0âSl\¡£Dt”IPCHpU[õÅÇô¶õä€~“[
´tí¹UğüÕ«îà7‚Rv¦KâU’t&)æšïÅÊ{tæÇ(ÔtHƒÎ´%LÛÒçíóÂàèàäíßÌÊ:Å©_@éBt&V‰†st«D.ç^³ÙÜàGvˆŞf mˆ³D­Á•™¿Ÿ­—×ÏRA{& ^;8óÒÇˆf;´Ê¨õ¬0FŠ”>LdzH­* ò“œ0m¨Ğ^ú‹¼ÿµ³[«íì6Ùû_µüı¯Gzÿƒä¿ºö>,«¾ü±»I÷?ê»˜.æòdùG§…_7øŒü·­í”üwv¶ó÷ÿ=ş—x|ª«¾:Å@_\W]½§÷ï
Ÿ‚HêV®Ò VY;§ëéÌ[bœQkÕj÷#—EñÈ'òÄ·{8ôİè˜_¾Í˜ÈæÌ]'6'kÔmˆûÒu“…9úú{†m ÍˆáÂÃcÎİØğQAhcäCp“ØmdÇY^X‰s+Y˜;ğºò’±‘ÂL#Ò]mÀœ"¼‚P$¢¹ı¨à·"O0¸=Y]W4aºáˆÕ—xø½½	”õ?(érAŠo)€Ôû8ÏÄ/+ö+E5çbDbô’NÃ¬©mM1$œFyZøNË—6¥Ä)|:“Eğ=fô‰D‰´é‚-ıc‘*İóŒm\º÷2Å|fê¸æ%Š+”1:EœÊ®‰Ñ•J…ö[b*ÒÙ©~‘"Ë Y?¼Ne;¼àğ	¯q¥‹˜Isˆ,r&ëÂ±ŸzêÌH‚ïq o®{í··ùÖ«Ÿ¥æ«úÊ´(–wm*áùª¿ö2Ğ‚è’| ¶P*ÄwP ^®ˆñÔğI*eãS¹o¯—:ËXPP]ÅÆ0œ3FP;8…“£ÙÑ+.á{T6‘[Ç.Üóe]•²ÍPpìÂ‘màĞ!] ìÁÉ°÷+fÈ‡İú Ï+Ïé^%Íú©ø]Q$µX3Aéd5ø†Íg³‡ƒi`Ìš^!ei7]¦¹sO|FwÙëP˜Ê Nhˆ)RYz’·¯ÿEÙããÆÿì‰ø¯¶Ób÷¿wwšyü÷İÔ^_¬-½Wß©Ôv$*Ú«Å1­$ºÙT;×N¯>¡Ë¤aİŸ{ş”ıÕˆnÿ mÙÛ×ªæ›—¤+¤Ê5ß¿
7™ˆ»ÅAõRu™*â¬*Ù
¯úœş`ÄÉ;H¤%ÀK1‰>†!›(fÊ!uÿq2ua{»¶[õ5‡¨<¾;ôĞŠåŒ)òDúïÙÿª£jCqÎ·(<8ÿÇA­:ıı—fc'Ïÿÿùƒ" ;ã§s½;Îÿv¶·Sòo6Zùùß£çÿ_’ş_]]m¦¬krÔCÒUšñÙ¤Ÿú
9ÿ_$å¿oûPvaKØÏôocÊİDó²‚ìU;Ë¥}5^écÒ“êÂ_Õ¹8äÖ¨|²cÊT¢ ‡üÕ|ÀĞ"şæ”Dú—@+V{<Ïçïj±¿fq½ª§Ó"‰˜QÌ’Uõ9[©øHòáX$§})ÈÙğbMmWÇÜöyºÚp.wOöGçrÈgtÍpüQ1-3€­6‹ÔO\TJ~Ù;ú<
Ãÿ¸XWÃºÄåéÏy±TPtƒr oÃ.İ}ì|½45Âè¿#¿Üğÿß 	üLüW¯·vBÿ¿ËşşßN³‘¿ÿûèùŸï"3®c	 úY…öSf(¶6<4T®?„©àyX!cr¢ŸÁîzP=E§‚„T´{J?^KwjÆúéŞ¹îI!€}Šc¨nªKu´ˆà{RÖhPpÓ(~Ñˆ.Ø¨GÛW/ĞšŞĞ (t‹šw*TÀfu9ö×@(DãÆ…½ÒØà0±D÷ˆng9ñ’´=x‰ºµË_ğ¤/â&Æ×Ï²¨åùuŞò–·¼å-oyË[Şò–·¼å-oyË[Şò–·¼å-oyË[Şò–·¼å-oØş¼YÙ x  