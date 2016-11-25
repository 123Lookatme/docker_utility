#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="4146123153"
MD5="1838e7fe3a221d27eedffeb59c1aa7e9"
TMPROOT=${TMPDIR:=/tmp}

label="Newenv pachage"
script="./init.sh"
scriptargs=""
licensetxt=""
targetdir="/var/lib"
filesizes="5563"
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
	echo Date of packaging: Fri Nov 25 13:10:51 EET 2016
	echo Built with Makeself version 2.2.0 on 
	echo Build command was: "./makeself-2.2.0/makeself.sh \\
    \"--target\" \\
    \"/var/lib\" \\
    \"build/\" \\
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
	echo archdirname=\"/var/lib\"
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
‹ ;8Xí<{ÚÆ²ù×ú™“üÄ»×)i©MNmğ»9¹6‡Ê’ ıÑÃ'öùìwfwõD8n»í½l˜Õîìì¼gvE±ôìÑ[ÛŞ^ƒ>+{rü3hÏ*µre—şİİ{F£kµgĞxöÍw=ÕÀOÃ¹ÜıÏÿ¦­Xr­ôüßû"ÿåZ¥RÇşJ¹Q)oøÿtü·ŒÃº.ºÓ?…ÿÊã½±[«ïV‘ÿÕÚ^ı”7üô¶ı¼teZ¥+ÕJÛoú½îÙş×ï·û’kûf@®Û~×îş2Â'o‚¾±oii[.
$ù®:1šò9}ì—&¸Ğìù\µô!\¨ÎÄJÒAïä¤Õ=ìK€ªëÀ›æªgĞ4ĞlËSMËp`Ç´@óÇ°<ĞM®– cÕŸy…"òb‚£(Sc¶€<Œm‡!ˆ™‹K ´1_b`ÌÍötŒğÙ#s×ªcªW3ÃMÂdĞÈ¼$KÒvÿ¼ıŞùh¡:®1û„ÜÒßTÿãÜ|rıß¥gÂş—ëê­RŞİèÿSëBšw
ğ™THusLK"MBu+H\©ŠBÓGØ‡‚ƒÃ>ÿ¸_½“Åcwj=ñ÷«WìezËµŠƒ0´©³˜õà³ŒO&Ÿ"&"ò±ábÔµ²Z´–˜ø¢ Ç´¼1ÈælfLÔˆíÃ7î¥%óM½ş¶ºŠIÔ‹Ø@%k¸ª&İI‚P¦…¢ciÆNá³”"Ó½ûÜJnòBUş=|q{ÑRşgø¢ muºƒ³V÷ İÌU¤-¾¯-60cK
+{ÚZİĞ–Øc‰vB$ıƒ»PÌÄ á1:İƒãóÃv&³ù‚Ïq´à&äKÉY%í2ÙÑÌÏ·_4ïä¤OŠ-,g-˜A¿ñLü.Ú…¤³Ìn2m!O‰‡³$t›–dÅG¡)n„?|ÙD¼ñéZÌqüœÆ¿íÎ;ıŸÃ[ÇÖàÔ´ÎÏhBÿ¬YY3hBPĞ÷> ¢Y€ÁÏÓuÀR«4 ½Í2¡0Rë¶e½™Çvæ À6v6ƒÓ›‚Š¬µç\Y<!G»EÌ‰ˆbŸ¦¯u Ü9 ,@n9,m\ß1~€‹e©;G¸d®ÁMçbĞ²’ÚÅòığÂh/ÜÁğ–¾ |FÍs|#Ñ!ˆÀ	‘x2VgnæØ@îŒO†æ{1;a¦ßâP…„5s;Ø*é,dİ2¼Ûù/ºã¬/7YåÜ·ğ‘İ˜]Á^!öu•BNàtO(pY©ßœŸ5@õõ·•_¥v¿ßëã&"|”·`LcAÆI6ÇvnIg¦æİú…·ñÑ7Q$ğ§2H2áÛo!Ù1T~9¸½… ƒävmí†Ä…}¸«\Ê	2[’Ñ¬ÀôejhÄ.Pğ‘ë¹\\tpá¢âcœ;6gá4eKMbŒò÷ş‰¢öŸƒCƒö«Œ‡—ÃG´sÜÛE%š{å›3.©bes¬vq2.2–ÀQôÁÌÙ!¿¼t_îğ™æ³’*Á)) °çl9rU6%¦ğ)²§Ti‡4>¥ sTE>£(®…}Û™ÈìñB SuuğÈLÛÌFÓ†ì7> 1C¼Š)fZÂ°’ÓÁäfyÒ+áoX3Çpq9ñšMÈ	x0¾ojX	+ƒ Ë‰+ÜÅ‡°gl²?™1æÆÓórhnpÃ˜'¶˜ÉCÜã‚Ò0âƒ‚ˆÏUòŸ?;ª51 Ø9mX^vw÷ùsqÀ ÑŸ†¥ßİå™®«™6+.S[å P—-Ò9½®·tU¿CÆR	ÆÑr'­Nw48ÿ©Û>C‹±fí+ÇÔ'ÆïÚå-¦½(zµ«¢TRûŸÁYûp„¾ëõ¬_uå*ò±ğ;Ñà¦ïòÿÊe`Å¢0›åWæ÷ÕFõ•ùò%
¯˜†ôö,F4x	åb9g’y½ÒÈ}ävRz#sé­ÈÆÑ0ÓòĞĞˆárá–*»‘!,‡ÁCÈGsÁ%“°7ªåv\ã#Y2Y`Kêšg¦BŠµBñèª€{/êq—Ïõî9jÆšÿ]”•ÿ¾¼,fæ˜2J[L·BŸ·eP°•As!³-r$…vkHƒXDÔ9 Š$%ê"{âü¿RiTj©úo­²[İäÿOÿgVñ¨¼vä¤C¸èuzİşEáûP’w{gí} ªXPßƒ7ıŞ	œö{ÿhœf,}üìõßÃ»·í~Ş÷Îá]«{g=hUÑ>´û¬¸^ÎmŒĞ›¥±?›*Æú”ôbÆø\’ÈÑ’GK–íqèİÔÀĞ>ø

ÌÌ+Gu–h f:eÙC¿ ÉÜaïàçvÿMç¸=øæŞcj ©.­Í|¥
¸Ì@[[=ÌKRgˆû”òªq;W™7ğ&IdÛaH¹KÜæœwúª˜bÒx­ÎP»{àÅLÕh¸ÈqbĞã;Ë…8ìĞ´ÇJL¨½AS8·‘J¦Åİ¢, ƒ|<â‚FÑÁë!`Œñˆ¢1Í8àÎÄ"°<`‰hìWPxGö¦¦<Ÿsä3¸20RÄJ‡1fzbÀÔ¿":Ø®éÙÎrl×öP;cnf‹”ó-‡Â$<–bOƒuPÑu¶—iœÚ¨If©3SuÁ³aj»¦EàÂvÁ¦¡ÉÇ0Xó8¬S’bNÆ¼Å=”ãîrnîC±TXÙ‘P¶0ˆ	==yŠŞc» tIÙÊ+ÈÚ×˜R˜:Û3e÷Gí/ºgÈ°Ä±îñÁ	*ä]Œp
_›pèĞwIjaAr¨‰Q´c¸#]‰ãÈQJ¡Lş‘ÒYÉ?’¿ĞòH\dOê|òéûwåïÊûß•‹Ù¢ì’j®
²$§êx¼h“(ëDEFİQAC$w“ÖQ»Û:i7síî/òHÎ…FoìihŠ.€¨àômtÚ:{ÛŒ=ÁÙñ~QçB3Øg]*¬#àğ’Ln5Ü`œààøø‚Ú×¦˜CVúé¼s|8bE–±|¡„Û`P¸qoÊŠÂ""Øâ¹Â5"">!\r‘yW2'½ó.+cå‚¿(ÊŒa\’IK–ûáP™‘Qà"¶`ö²)³%BÛc“È_eÌàı!wXÁ,0):ßQ4
g™Ó0µ ¾…¦ÏU\ÏFM×e¾¶ß´ÎÒº2Áš	ƒU³Æªæ¹Åb1•ïKo¨¿)³}*o :Ó‰Œ…ûÊ•Bd\ZIƒ¹ƒ±®ô ñ¯œ‹KÓ á+‘€òár€uTd€T¹
C!>¸³‘·N©ÌÊD™|‹¬×®sı©ikeN b&K˜9!ÒÓäûéó}–®Åö-İtÌòlÇ4ˆÛ—^|ñ¸¶°gëˆ°q !ÆDåØ'zpòŒL²ˆO+<J‚Éi
´I^Ğ‚¯zVV¾
ÍÊ¥L°™€.„cÔNZì_zf°y'®‹Š|9V`MCïb™Ä—×qh±Dmtñu».WyÍwˆ¤MQ6T²}ŠK¸P¨e¸™sc˜|à‹órhSÊú
|æåÃá,Ñ‚ ÜgKc0çÍ0ªNÂüVôûÍ2„j˜Ü]J [ggí.ùî}8!d)†ãÑ÷—QÅø…”À˜/¼%î-’ÀÒÙä7‰@/­¤lÕ…`EşâÕÙ
ÊÚ6‹Rö>°i!4æ/ È€„$E“’pBûÄLÜ¡Ö*@—#‰4,˜¼¢c[²%>„?*ÿ4´hq¹°™…È<<È‚I(îX³áó¿›Hÿ‚%0´D¡X«¾gsLÑ O«®lÛã‹:b:EìôOÂ3&=0ÒiÏ<‰ÚªK¦º¯µHÛÌVÆüa"¶ŠŒIa­o|èaÇN¢ú+6(¾ØÊ‰•ß~Ã|æÔr? ZÑgcÙ¶-êtœÏïñĞƒ8’Éí¤¶ 5‰×.ÿÁ#6'8ç‰œ`yÁíP"ï“ô…Ü±ÂbÑ­qõçì‰ÕXD&éÅa/Èò3Ÿ”e£Dt‡T¼Iˆ ñôÏ»ÒZS2±62“všõ¨„.HÛTù9ìX½ÃjÍˆv(|‡ø¨ ¥ğ~@^¦åKÚ%ûâ‘x>Ÿ˜V@WÂë×‰‘Òâå(o1ŸÑ-w®º¥LÅ?²mJKØ/¤|ÕRÿî÷?ƒ«5Rÿm¬¿ÿ½»×`õßÚne¯R¥ûŸµÚŞ¦şû×¨ÿ²bæ]”–ØC‡˜+·øUÎ¨ì÷SxK3˜ÏÃôğ¦RFİ•Ï(Á1ÑåÆ‹ªt pF5,ZXT_)!vDKVf‚ª.ZQ± ê%J^¼n†Öœ¢ITgŒL¦6æòaRµŒ%øLEt#€©ğ²^XËMÆµ¼75=m…#š†ù?³÷f¬&ÉRì*S3ÈÛxD»›M|c÷µ¾ÒmÓbÉ´Lï±n~?èşg­Q©Gï4Hÿ+ÕÚæş÷Óßÿ.‘B<{D2†“Èæ¯¨/¼¶C•¡™i}`—@Ê…_¥X¥²)s©ıM²-¢KNŒƒXùÍ¥Æ˜Û×FhfĞYÔ…§LP©¾ƒù»pá ,ÃşB§+L=L)›ôÜ:‚*ÜTğÊ—Ätƒãuåª¯Kºq]²0.ˆê‡äaêyw¿TÂuŠ|
nq·àú:Ú“©¬¢š\-clCÒ¶ºXÌ–Áıu‘Kí£©ÉE$”4Õƒ×P2<­$¦õ€”ØßO£0ò´8e›ñÉ&3gŒö¯ÉÑ/KÛ(%ºö»[cJæ:^¢^¿ cğTŞ­×ï†z‡†«9&K¥›ïÅ¿¶ĞÚO¦ŞAÿ‡Ã·§@Ñ¬¦jSòü¡®^6·Æt¯I°€:MÍÈC	½E‰çºø±ƒˆŸ—6¤ü„ûÌ'Šòrr7ÄÉÎVDdD”¼·!K\e©)2v®~ŞKÜ‹_rE†±»®ø}E»˜jÆu&¡‹ql¥XÉ0©eH)'Ä!uW–¥°†/—Hzd‰á&ö@Tb,yĞvRD—wè>ÒBuİ=);(®Nñ8Qùƒ$#áÕ%Z…½ûq’„¢(îÔ@Ì®·)i0‰Ÿr`“ 
åJÂ¬ô!AU.ÂêËOé'ÌšÉÁşyE>ĞBßuJ.á#‚¢ï¿o÷ŞHqÛ+vÊ®¡ÄÙ’x;+–|òô$ˆ±˜n¸±r1cÇñ£j:¤Agšg&méc§æe®w|xúîÛ0ÅOQê-(mˆ™‹Òp‰‘
m—S¯Ñh¬Ğ#;ÙêÚ¦s>´Ş®ÏB¨±?[>O¥_™ xqèÜMŸÌ›ÍĞÑ¡Ô³Ê'	RúP?}7À-BjU•(ş=À"3†÷?ë»år}·ÁŞÿ,W7ï>ÿçK÷ã¬ôçó»Ùû_•İFcÃÿ§ætrşuóÁ/åÕ½ZŠÿõú&ÿ{úüOâ‡2#L•Ô&zâ:úü½«, ÷9ûîä’y˜À];Eå½rùŞqä_)xúLaÃİ>}?øïcDÜeLds&Î"6'kÔ]ˆûÌ|u“…9&÷[A<šÃ…ÇòõØğQAheäCp“ØÛ”9X‰Ì‘c&:ü8cÆÈH1æ<é®&`^ÇÉÓ¦¹ı(â_yq{2_5Œ·ºáˆk ğğïæ*PÖÿP $H])şJ¤Ş‡Ày.®xrX±o©]s*f@$BÏèlÖÙÖã×Q”4‡ïÔ²än•KÂ§0Yd
ì>”(‡&] §XXM÷¸cŠKwÀF˜|yì
yÌCdT³k£bt±X$=cKŒDÉa¤_aXËÒ]Ö¯S©Y /8
…“%ê±H¼Dæ“uáØ\ul¤Á·8Ğ3ç†í{Í¿¢~3¥‚ğóÔ|UŸ›%M%\Oõ|7-ˆ^‚	ÀævvrâoP R®UòãüğI*¿äïòÀög:K¯Q½j9'ŒØ1´®ìàLXfG¯°…¯Ğ °‰ò@ì…¾Ì‘£Rj2]Ò¤íÆYD'j8´O¨[ÇÇpÚïü‚éüQ{ ½.À‹âºWM³~Ì“—#NM}Æ(¬WØ,6q2»8˜Æ¬YàR–vÕØeÚ™µ:ñÙe¯;bŞ…2¡M!&HéÙ¦}İø/JuŸ6ş§`OÄåúûı‡İzcÿ=EcojøW¾åùû•z±\—¨Â¬pÈ¤B’èÍT]&]‡lÿÔiuGìWcÚİÃ¦e[L¯UÍ3¯•J»²äú«p“)€8sPœ1”®U‡‰"Î*‘­pK/ècNßC"-^7Jô1yÜD1SÖ©ıÏÓŞ µZy·äiÚåYÿıi¯ƒVôBÎ˜"¥ÿ?ú¯.Tmj(‹éâ1Š ÿı¯jy¯V¡ßj”+›üÿOáÿ#Øz}ÿ«õzUğŸÊ8®Ò¨66ùÿ“çÿ¿%ı¿¹¹YMYW2Öä¨‡¤«4ã‹I?ôrş¿HÊß ö¡ì ş°®éîÊ”õ›~ô²‚ì–Z³™}Ó^7ëbÒ“êÂo¥‰8KåÖ¨|²3ÕT¢ ûü§7€–iè‰®	åRØ÷€æKîóW6Ù–DÄ/i—éÇô{DMòY,+½`+åÿ 	~>‹ä´ßŠ8üm¼‘íè˜â¾H÷@.åöÑéÁàRéŒ>¤.€_Š¦e°Õªa‘Šû€ÒC90û)
¹á¿1˜ÀÕ°®qyúU?–ŠnPáM¯ß¦›·İÃ¯—­FıWüÿ#$_ˆÿ*ÕZ-ÿÕë{›üïÉó?ÏAb,c	 úY…)3:M•åÇ0¼+dìÒTô5Pë¨ÅSt*h:HDøt[êOenÌé›ÌûYÕ,İ©a”ë¥{'zº'…ö)CuR]êB‹èqOF
.‹ÅïŠÑEÅ¬h;“’ ZÙ[Z…îöóN…êÛ¬lÇ^`§ÿŠ{û·Àa\‹îZĞ~¸ıå›—¤mhéÁKzÜ úgšnïˆ[%_?	ÿ®¼I¿7mÓ6mÓ6mÓ6mÓ6mÓ6mÓ6mÓ6mÓ6mÓ6mÓ6mÓ6mÓ6mÓ£ı/ÇŸq8 x  