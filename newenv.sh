#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="3530300066"
MD5="11fdde05c0d876a0cbe7bb56cd8960a5"
TMPROOT=${TMPDIR:=/tmp}

label="Newenv pachage"
script="./init.sh"
scriptargs=""
licensetxt=""
targetdir="/var/lib/newenv"
filesizes="5658"
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
	echo Date of packaging: Tue Dec 20 15:58:49 EET 2016
	echo Built with Makeself version 2.2.0 on 
	echo Build command was: "./work/makeself-2.2.0/makeself.sh \\
    \"--target\" \\
    \"/var/lib/newenv\" \\
    \"work/build/\" \\
    \"newenv.sh\" \\
    \"Newenv pachage\" \\
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
‹ 9YXí<m{ÚÆ²ùjıŠ‰L‹I!À`÷:%-µ‰Ã©¾`7'×¦TFè	HDv|bŸß~gvW¯Çmc·÷\¶O¬vggç}fW.êÏ½•°íîÖè³¼[+Å?ƒö¬¼]ªìT¶«ÕÊÎ3½]{µgOĞo¸ øÉÜûÇİÿüÿh+ê;ÔŸ‚ÿ»âÿvûË¥ZygÍÿ§ã¿Í®™}Uô&	ÿkh’ü¯lï ÿKkş?zÛ|®_Z¶~ixeóM·Ó>İÇÿ»££fWñœ…;dk7ß5Û¿ğÉ› o´°‡¾åØ
¢,<cÌêê}ì&8:³™a›}87Ü±×W”ıÎñq£}ĞÛS Ã4A´¡ËŸÑ4:¶oX6saË²a¸p]fû`Z.\Ş€ÉFÆbêŠĞcòr‚£i6CF‹ÃÄÔÃ%ÚH,ÑcS6ô?!|şÈÃ•áZÆå”yI˜|¢™G˜Çó½©å!¸‘ø	SËşÀL¸¶üI´OQe³{Ö†nçìÉ97\$U ÷£ò·Ñÿ87Ÿ\ÿwKµ
éy·R­îìn£ş£Xëÿ“ëB>·
ğ™TÈğ¨¹²
–­&¡º¡TE©éìCÁÁaŸÜ«Ü©ò±7±F¾üşêÿ¢Mn…V	l8qp·bûd‰)8aƒë–94|Ètönví-°!a“ÎŠÁ!^Ôµ„X„–œø¢ s×²ı¨ÖtÊÆÆ$öàïÂVÅş_[YF:êEÄ¡e1TîISËF)³‡l«ğYIQô^’lÄéhGµõ_Ü7´ÿé¿((­vï´ÑŞoÖsee#NŒ-(,íicyCr7Œo$Ú	‘ôOîB³ƒ¤siµ÷Îš™<Ò¬ú1ÇC+«Y×“³ôáE²£'o¾¨ß©I÷[X>ÏZ0ƒ~£©1şC´IçÌ¹‰åŠEN"gÿH8˜¡ºá£Pá´!n¤ë|YG¼ñéJÌqüŒÆ¿íôNZİŸÃG­FïŒ4ÎNiB÷´^^1hLPÑñ< ¢U€ŞÏ­“UÀR£{Ø£½Í2¡pR›ÍˆŞÜ¹»36`	;
ÿl kÙÜÏG)&@Ûİ2¼ˆDDcä¤é'((w.hsP.ƒgŞÂe?ÀùŞîƒŠ#¼92—IkÅ¹ô…¬¤v~ó¾Îšıs¯×¿¥ŸQóİKtH"B$ŒŒ©—96;ö‰~Ì¤gXtwa¨RÂê¹-ì
£”Àt²ˆn3ÿÚq?¤çËî‡Áxë+LVÀB5·åÏÈnŒá.a·û9‚r!'ñºÇ.”
¸¬ÒmöÎNë¿ òúÛòoJ³Ûítq“1J…[`c—ÍÉ8©Ìu÷–„pjıÛ…Mæ­Ë>.,	$Ã9<Ç©’
}øö[ÈBv•‚„ŸFno!À ¹gø£gÂ\ÈU.Ô•/ÉiVàú2aCb—\ø=¯S œ{¨ø¬©ÏÜºj3V'ÆhqïŸ(À ‰98”	´_m8\?ÑÎq|åhîåÂš
I•+[3dµ‡“q©h˜”±²¦^Èõå…÷r‹$¨€_TšÏHª„ ¤„ÂŸóå0ä¨ğ)1…È˜€O‘í8¥B;¤ñ)È˜ *SMó—Ø¹­1C`ß@ô˜†ë7¼È´M4mÈ~öräULÁÄ3Ë–†•œæA3L©^IÃ›5‚ósÈÉGP¯CNÂƒ~ÿøf'¬,%:.qÂ‘Å¿rc,Œ§¿pmÈ¡¹Á}Œ™0On1“‡¸Ç9elÄŸa ˜ÿüÙ5ì1ƒbë¤q\Üç)ÜİİçÏÅD_™mŞİå¹®«Ys>+.S[e?Ìäø"­“«jÃ4Q…ñ7d,•`-wÜhµ½³ŸÚÍS´+Ö¾t-sÌşĞ.o1CöA3‹¨]e­RPšÿlõN›\ğ]§ûsoõªKPi´…?ˆ†0}Wÿ5—v¶¶Àª—^YßWj•WÖË—P(¼â2ÒGÚ³Ñà%”Š¥œEæõrHî#·•Òƒœ™Ko½@6†Yö‚…†FW‹W/ïD†°!­¹LÂŞšS¨–ÛòØG²dªÄ–Ô5-Î(L…¶Åo0 « î½@ª'\¾Ğ»ç¨s¨ÿ~=/iÿÕyQÌşÌqeT6¸:n„>oƒQ°‘Ak®ò-
$¥v+HƒXDÔ9 Š¢<[·ÿğú¯ÌãŸ¸şS.×jå şS+UDıg·¶®ÿ<uı'³ŠKåÕó ĞĞ‡óÎÉi«Óîá7ÊÉúŠò¼İ9mîÕ9ƒú.¼évá¤ÛùGsÿ0íâg§ûŞ½mv›ğ¾sïíS8í@ãà ¨âŒF¿Ù…` –ètá¬×Ä´«®Óé`n`G•fÂsEÙ§è‰Â”déØE€ŞMækÁOĞ`j]º†{ƒV}jâXFA)Du¦7­£fO›{ùŞĞ°qéátaòü—¹¶h+«ÇyEéˆ´êF<jš<ÄŠğ&IäÛáHy7¸Í™è\Ì©b®ëWÆM6ˆ°j>5†4\&®1HÆ¹7sÓ*Ø¢i!!•mR{ƒşmæ •,[ø~Dx”ùxˆ+6×œ¢ç’×}À´ƒLmÈ1´â€[c›ÀŠ(4¢±W\BámØŸXˆ"Iœ#×˜Â%Ã×p+F˜¾Ë“Å%ÑÁñ,ßqo–À¶¹59Ó)%ò7 ò ó§Á:¨è&ßË$NmTƒ$³Œ©exà;ü Ó"a;çÓúPc8¬YÖ	I± cŞ|a‡ëmnîAQ/,íH*[™†áznJÉb» t9IùÊK(ªq®0O´L¾g*ÙœºÎbŞF8}õ8uGNP!ïaè‡SÄÚ„ƒD‡~+J³B’û@}HŒ¢‹jÒ•8lõ1*Ï\!R&?ò‰ä/´<ŠYöÉ˜ÍQ>´9|Wú®´÷]©˜-Ê©æ² +jª8+*q‰Z]T9);U©dÆŞ:n6Ûãf=×lÿ¢Ô\hd0¢Š=MÑ9e9	ƒ~N§oë±'8;Ş/‹—h»¼+@…×Ö$QgËm¡†3Î	NŒ/(¡}­ËY1d•ŸÎZG=SºKÂJ¸E÷ºªi<Ìå°€ÿ kB#"2àÂ%™wM#óxÜ9kóÚd.øF©Cc]å$Õ#,÷Â¡*'£ÄEn?Àìe]åK„¶/Ç'‘¿Ê˜!úCîğ*h&`Rt±£hœ TC3§a¾H&6š>Oó|5İT1¢Ş|ÓØ?í)«j?‡h&/QŒ¡ï‹ÅTGyCıu•ìQÍ
Ñ	X˜®æÄøP¸¯æT.DÆ¥‘4˜{1«êIJÔ¨¹¸dñ1ê¿’U1\°*G:ĞCa(Äçƒ<"oR™¥‰*ù>.­\3æúSÒ2ÖÊœ@j^„HOSï§Ì÷Ùºga›”}š–ëbêî¸#n_øñÅãÚÂŸ­"Â*Æ‚•ãŸèÁÉ3rÉ">-ñ´¯H.$§iĞ$yA¾ìYyM24+*ÁfS	]
Ç*¨­´ Ø»ğ9Ì`ó*N\!År¼j†ŞÆ2‰¯(ÎÑr‰8Úèãëpv],óZìI›¢l¨d{–p¡PËp3[gÆ0ùÀç)äN(•/ˆ™3”_†³DpŸ-ÁœÕÃ¨:	Wò[3ï7Ëªarw)nœ6Ûä»÷à˜¥NDß_FãR6›û7¸_´HK/d“Ë®]^ØIÙ&ªKÁŠüÅ«²œU8<JÙøÀ§…<äĞ¸¿€ R:DMJÂ	íO3	‡ZX© m1&Ò°`ò’q`|EÈ–ø8ş4¨@üÓĞ¢Äıå*Âd"‹ğ x&M ¸cÍ†/"üv"ı–ÀĞ	„bm,|Gø`ŠEZué8¾XĞÓÑp«{Jè‘N{æLÔ–]2ÓDMÙä¶2æ±UdL
+}ãCO°¶G°dƒâ‹-sQMõwÌçN-÷¢õ}F?æø‘m›²ø*ø÷ü>ı7Ès¶ÜVê´R“øàpíÒŸ<7ãs‚Ã»È	¸Ü%ò>IoQÈ«Ç]"Ñ
WÆyEf’^Qà‰*»8ÈKY6ÚHDwHÅ›„Ê‘ØH÷¬­¬$0%Ck#3ÙãG”Jè‚²I•ºÉÃ-!?@@´—|
2P
/}äUÚY^^ğoÄáb³ş:òœù|TXåNÏKMSáõëäE£ù2'Ú'ĞŞb¶cÚŞÌğ>*™fáĞq(ie°WHy¢¿où<Qÿ•÷¥¥ş[[}ÿGÜÿ-oï”wË•
Õ·w+ëúïß¢şË‹™çtû©¯ó‡ö1W8jŠ«¼QÙï§ğ–n0_„éáõ³Œº+/Q‚c¡ËUé”à”jX´°¬¾RBì1DË^æ‚ª.ZQ¹ á'J^¢n†Öœ¢ITXŒL&æòaRuK,ğ©èF S;e½°–›ŒkE)nbùÃI‡˜ÿs{oÅÊ`ŠªÄî§Õƒ¼MDÄ±»ùÄ5v	ï+İ.ê–mùuóÿA÷·wK»ÁùÏöNmõ¿\©­Ïşş¿N
5ğÉD JL"ë¿¡¾ˆØU†èŞ;¿ÙS*ü¦Ä*•uUHíï’mùnb¤ÄËo:R^p¦ˆI–tµÅ9læ\±Ğö ş s_£¦Ï.&õÒsƒv>XÌMº|ƒFĞÃuœRÌ…;¥‘ÊfĞ\FDÔÃqzÜ¤Ğ® òZ7Ù•ncV]5#ÊëÁÄ÷çŞ®ãBE17>ƒ[ğ&Z™I¸Zˆkrµ4’±)›Æ|>½	Şj²â;4@¹ˆ°
İ£~:ó‡ºœ^4c|ÿ=BêÚ‚ŞõødMœ;B«Xè—”M”Sû=…¯1!#/\¯^Ï0h*íT«÷
Àæ]‹'ØuŒã?èÆÿšÑ¿pğvÿ(ÆÃ	yŠQƒ¯Ó]a“, NkÈò £ÑEvhÊÏ9ˆøyaC&ĞàŸùD©^Mî†ìÄdOÿÖ_è›ô¡çÅx™“6º`7õ“CQ¼)ÃP¹,ãÒ U6gÆ‡à­Éåø½gd,¿şŒ¿—t“+v\ãšß•+8&ui§Ä¢æ„Ø¤nf«ª ¨:I™ªpÜäˆšœu2+’ÚÅÕîsÑµ¹áy×fRÆP¬İw²¢,ô5HeÂÛl´
sè8	EÓ¼	CÜ*lš‹i$°šq – %]ò¯u!A`!õÆËOé'Ü,ª)DÂF!C ¸ÏÕ=BMFWßßì¼QâF\nš_RŠs(ñš_,‹™L¬quòbug:ãG;šiç¹à¥Ï¯ê¹ÎÑÁÉ»aö´EŠRoAkBt^]Œ†yh»‚zµZm‰J ¨ÁqŸ<{áI¤|"­¦|”Éµ?àĞ#úoÁ£·Ñbzó<•Ûeu©3/})Àª‡>U†]I
Ó÷	Ò×¼"¤V•PÅYæŸÈ.‹Üìı-Şÿ-WwJ¥êN¿ÿ[ª¬ßÿ}šüŸø?»ñ>Nõ¿ÿØ]£û_åÚúıÿ'çtrşuóÁ/å•İíÿ«Õíê:ÿ{êüO‡2ÌŠŒ&zòƒÙzÿZ›Cîs¸İ©:REL <2Æ2¥İRéŞqää(æùLŞşn‡¾ïı÷÷ıwùœ±;ÍÉuâ>uÆ_DÇdañÄ=Ã–Ï@†fÄpÑ¸@g56bÔCZùœä$ş
	åˆV2G˜…)8Î˜r2RàÙMº«˜ê„×qò´ia?ŠøMæ1ÂÌnŠÃ ï‰­A€ø±¿×—òş‡%9@ê"Hù-zç¹¼â)`Å~¥v-¨˜‘M€ÙÇ`9ˆÒãğj-sI ÒÄt¦Ê ÿœ?0û
åÛP§·"è?Óåü˜âÒ°¦Oƒ¹k]!»B‹8UF¶üÚ¨],IÏøY\˜—[òÄ–÷ÃëTrÀBáøõX¦Ø"ÎÉºì1bi@ğ-ô­s~}[¼wp=¡‚ğóÔ|ÃœY6å®C%\ßğ^Z½Ù€ÍmmåäwĞ \®UŠãüğI*CMìrßYLM!£lzwA¹ch\:Á™°ÍŞKß‹Š§“á[Rb™C× ä6d¿¤IÛ³ˆNÔph—.P7à¤ÛúòÃf:m€Åt¯šfı˜ÿ&¯Fœš,8£L²Ba³Ø$Èìá`³fWHYÚec—igVêÄd—¿ÃŠÉÊÄp1A*¬_HùÚñ_”o>müOÁŒÿJUñ÷?vªëúÿ“4ş¦Æâraû‹½rµXª*T#^úãR¡(ôfGªd.“®C6j5ÚşWƒšíƒºíØ\¯¡o]±¥¢ºv#ôW&Sqg ¹#Ğ¯—‹"ÎÒÉVxúúƒA'ï!‘–€(÷$ú8†"n¢˜)k„ÒüçI§×„ííÒîç´ËÓîû“N­è¹š1Eí+ÿôß˜Ã	Óæ“ùcšÿ×J•Òîv™şşW­T^çÿ	ÿ¡ÀïxT««ø_©V+’ÿTşÃqåZ¥¶ÎÿŸ<ÿÿ=éÿõõõrÊº”±&G=$]¥_Lúù ¯óÿMRşûññ{‚æÃfx–Ï¼¥)«7ıèeÕÓÓ©sİ	^7kcÒ“êÂ_úXš
kT	>c§§q]ñ÷T€…3Ûbf¢kL¹öı y½%Ò}ñÊ&ÿK4ñõáEú1ı‘©ˆ&ù,–é/øJù?D‚ŸÇ"9í÷¢ÿ6âÀqMLq_¤{ jóğd¿w¡†tFRÀEË¶ØF…Ù$…òÆ> ôPÌÿ¾Š
¥Üˆ¿1™À•ÙW¸<ıUGÊnĞàM§Û¤›·íƒ¯—­Fı‡GKşÿ’À/ÄåÊöv*ş«V×ïÿ?}şç»HŒ›Xˆ~V#EÊÌ¥NÃCÓ@íæc˜
^„2~=*ú¨uÔƒâ);54$¢5|º-õU›±İöa±É¢ŸWÍÒCŒrıtïØL÷¤ğÃ>mÎ7ÕeÌ‡=îÉh£AÁµ°ø­0ºmà ˜w¬KR¡•½¥%@Óèn¿èÔ¨¾ÍËvüvŠàÄŸæâoÿÖ8œkÑ	Ú°¿bóŠ²	3xIOÀ…+Ş™¦û7ò2È×OÂ¿+­Óïu[·u[·u[·u[·u[·u[·u[·u[·u[·u[·u[·u[·ÇjÿÜ	]  x  