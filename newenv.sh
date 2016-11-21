#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="2155726859"
MD5="65ad0ac62d1a6e6fa5f13eb6fc1a7614"
TMPROOT=${TMPDIR:=/tmp}

label="Newenv package"
script="./init.sh"
scriptargs=""
licensetxt=""
targetdir="/var/lib/newenv"
filesizes="19837"
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
	echo Uncompressed size: 328 KB
	echo Compression: gzip
	echo Date of packaging: Mon Nov 21 14:15:45 EET 2016
	echo Built with Makeself version 2.2.0 on 
	echo Build command was: "/home/user/work/makeself-2.2.0/makeself.sh \\
    \"--target\" \\
    \"/var/lib/newenv\" \\
    \"/home/user/work/env_common/\" \\
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
	echo OLDUSIZE=328
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
	MS_Printf "About to extract 328 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 328; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (328 KB)" >&2
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
‹ qå2Xì<	xeÚEÿE;x ¨ë±~¤6Ô$3“«MÚP*m‚iBê$™´¹˜™ µàª»(»x`õ×U×ëYÄ…ÅEEe×]uÕ¯…UA¼Ñı]ïÿı¾™ÉÕQ¡e5ó<<I¾ùŞ÷{ïk¦˜Ìeı¢ár8ø“qØõ“&ëêUÆXhÆj³Ø6[ÍĞ¬ÃR†leƒp¥%™*KğóøÄÜ}íãÅ²ïße2KbØ<èú':ï¯;kÃvÁ0´•=Äô/&“ò÷Vÿ
ó&©{Hôocšş‡ö1¬ƒ±–!º¤ÿƒ~UŒ6‡„„9ÄIİTÅD¿ÏÛVÿü¾æfŸ’’i1Ì#½×3ÍãÚ	w&jkÑt",É„FCQi‰ëâ]ºvüáDŠ(Q œŒÇ¹D$ˆœØ%)ªŞ×Òâö6´:)
!.AÊyNæ1
'2'$xU		N‹"ŸQDQ¨Eø(—ÉjåyT©ƒñİ|,…*Q4)Â6@“àÀUhåc|XFänğ“[BšË‰ŠñR>N¨"ÍAYIé(ªÂßîE~_{(Å‰ß©ò‰ôã©ÿPÿÏÕæ û¿û¼ÿiÇ‹•±—ü°ı?Ïš«¨»'ñH§gtHHPØ“Àİ”âT&ÕÓ;a¶õw²uêm©[ˆÊê÷º:òÅØ½@ñ*îN‰
?_P@T ìˆÊŞÌax©ßiÙ³TÀq”…„E:!ã»¸Rs¢1RGB§0uöX¶?%ÙU 1Y´¼Ä…©…”*(!¦“óU†^ª@Lûä³<ŸÉ g¼08nAÀmœg Ê›¼­mno½Ç¥g¨r…¯r²±K	ıx*ïÏP¹ÊFFÉr‚Eú¹0
y›ÔŒÑä­onoğÕ‘QpS`$"¸€*ÍùPæpGş‚«ë¼bœk¡.?'å¬Ş/v`ùEc\×·’]FtÉ‰›Ä[p¦€LÂèñ˜†H¯Šne¼Èæ‘š«]@7ÜrØÇû'ùZÛšüû±½[Ûînnr·î g@îö6àos1lêÂX!÷MùzŒ°ÓíolÅ¼a™İEDI&x,O’‘Å8RB ¸XÍänÄê’ñ”Œ$TØ…94d°¬ÖY0ò8ãŸPU€]‰È˜B:·È£dIi‘?zÌŞ ÒÁ)Êã•P£hI[Ë¨
_éÁ ï	¤ÖàüÃ€2÷ğ%‹i>oA‚"ˆ¼;Q.&İ«Ù?Ÿ§åœ8\$‹é„‚Uµ —¾
–2…ˆÅ„àåyIqv!¼º¼8BtUB’¦B¾JN¥AİPx…Ãó3Šƒ^¥[[îm€c)¿§µ½¹Íu¶±ge. <~¿ÏLª„(»thâ»D>…ƒÅ¤¸ aLËÒ	\.ù9iLÄ@£”`Ò¡ ;#6ŠXƒŠ¿8´`Ò(Èg§!%/!Á‰:ÔS:tytäH"3ñ—n>ŒÕ¥ÌpK’%Å\"
Â”ulTˆÉ¼èÒ%¸8ïÂŠ1ÎŞçãª<‹I­¼‚ókŒ"ØnnÈÜÂœ„&J1ÅRÕ“…8¨Z`8*»Mµ±<Õ5“2êĞUwHÕUØ‚ğE‡áÉù.¡HRÅBî“ãd¤g	HC€» v a1‡xÑHUû£QJ‡`é«ºxĞ ¬u*+''Š\¦#)ÚbIm ~~63ĞH]ƒ)÷„„…qRæ%}PšOÈ%DQ €ôê-är!½ŠƒuHîæyQÒy!àbvf%*¯$+ÁSN‹	¤‡p|tñ²¦<•Å¢:S¸ÍÂz0áqNF•½½"—èâ‘©iŠ»ÅTOú®…{{M­şÊ'"V_ÕNR*×¦öï”zÍ!$rHÓ”¹Vw$.¿Q‘£ò‡kq7y;[Û'x=m18;$
‘.ş[q¹ ÚZ#&ğ.ÆÈ(ÏùM­m†N8pšÏ?¹uàSûİ §1Î1|K2”Ğ7UÎÔ¡ŠT3UUHpÑuÂY¬­ª«‘ÁPGl0#5åU#ÚDë^Caœ>ôU~ WwêY7à‡·	‰4Ÿ	4êv	ğš{6Ò™â!£G!¥X&¦^HáRL_%ñsp$Ó©Ôbw-4g0&C,Ó(ØXÄĞìyJÆWÜn48F
¹.B3´±6Xİa*ş©'¾H•o,Ï¤¼r× åÄûÉ+ª.€I3 â¢İYih¬I…¢ö³ÿÏëã¹ÿghk+˜ÿZl¥şğûÿ¢S<<^h=i|SÚš|ŞVø†Ëû EöúÚ<N„§bÚ|MôûZĞ¿ï\O}‚ÅŸ>ÿt4m’ÇïAÓ}íhšÛÛ†Ú|ÈİĞ€ğÄâ‡Ç´s´´äó£öVTğ.s4‹u¦8èpÓãhŠªÇ‰g¼üÑa2šE4­›‡Ò_û‰Œ(&„DNì ‹À^Ò]dëATßà«ŸìñOljö´R
sÓ¡us	8:KGH+ÇÌKhØœVR”Oé¸åårpœ#Ù:K7¶DÂ!Jê6ãÊb:…'¦Ğ4ÎåbàıHÉĞ©ÆÛÕ(TbO*	:ªÂ`£‚Æ_!TÆ“ %!¡¤ ‘‚UæVK
Ch‘h@ÕuA…õŠ1L(ìÎ¥L'ŸA.&p’“¨;)ÉËÛ„X¹”=W<×¬yåè|©D}QªjP$àD&³¡ªf
ƒLö„À‰+b7´™!:JL®Ü-HˆœÜN*É¹P¦ôŸĞÅd:å<ABuW.Õ>es*%È¼ ¢œiPÉÁ¿)ÊE9¶Íä°è³+Í0È+	Ä®pw<ˆŠ1yVgo¥5óó¹x
¬Zâº†vÖĞ¦âê—°9÷W>¥+˜})ƒ¼QHv0×Ôânôxİ-—ŞãªëÔé3n€]ê4Cm¦ğ¯Î)î¶I®œ;ær×Õ™„?YÒ©MI¨x”ñ„¾
¬'VĞ)ûT&Ö¸T¨\ª&´757t’¢Wa9½`ÉpC°(Î¥3Iõ@p!òëÒ¨Xº>wŒ„}6Ô8T´øÚ½d¤£×¾áŠ,‡b³ÈÎœ¥Ò™Ùª#bTiQÙ×(«véÈ™8ÙG€pì.¡¬g´C†GEcV8ÊîSkC¤¢`P†ãp†Ò‰äFIN‚GtP¨TLt×·µRµÔàş<™üD¹°,™L¦‚Ş˜šˆ×]:òáÄ£ 
WÅ›ä=öÕÊ3†lĞpÇbx ÔƒÎµé.‰æ¦NíÎXbU…í7*˜š3ªäJ¨d¨Nœ¢
|£q¢ÊÉtûwJQ :-Ğng!tû–nNŞM$!!$Ó‰.Ù#‚(B¿“ë²CÎ=7×È½8H-ˆ‚Y³=ùD¨	,ˆİ¥õS¥ª,Ìˆ<Ø î’GN&á#d“	:Œ›Wf…H¼P¾ä#PFg‡Ü!÷ÃYM“ñÜº¥£¿ğ•#×V36íTPa?Î”1êªj— ¬ÔRZ%ÎÜánÜ“È8(LV+)À€0‚}…®œqW¦ ËÇ«*ÀÙwÌ:Q>wænkóxq
t¢L,hJ-ü¾T(°Uòñ”ÜüB P©”2jùy¢ H;ùÆ†¥®ÚQ6<×`BÚÄ5I’½SÓËè`#áYE„Š`Ò2pF…òñdbVz(ùË0 {•}Ø`²&¯÷3z‚ŒœˆŠ[|:lü…¨4ó/Ä–e 7=$XŒ™TšJ6.†<ƒ¦P@¹y¬8~oRKöæuÚP¡€À¬¹´œTR.ª”Š>¤r‚¼‡`5ù[2?TìZÔ,L„­jĞ?â‘€2 *HğÊ¦Ÿ¼J&K9¼íïà½*o‹ú\ôı¦óxôàIZÑŸdÍ¨ÌI¬8€r×ß–ë2CPõ±€¾ªàá
* "›3gÒßqÌO`´gÙôc äWdLo_&İ„KÙœáV¡ıD3@’m'O2H¯v^’I}à •ç!3’•7*¨ã0!MSt
#ĞùS
7Y•fãa+y¢rPm *ğt¡Á«–•Ü§ Ü‚}vÆ ğ¶Ôlì¿ÆùÈ8	ªùHBŠsÒª¨6&“¸Ùâ‘ÓPú÷gêvh¾ÿ§½ZqPæø½ŞŞÿµ;”ùŸÅÎ8–Åó?ã8ÄæßÓ÷¿vşG†Yü¢DĞL>”b0t³»Qy•Ï(h’	™·ô4x‰çÄpwæM•"s72Âe¿ y/w¨†'æµáy>X¾á&Pâ¬"ã@‚I›êA„Sää¼ñ2‚H‹K:pb(º“Ğ¿fZLòÖÇ8 7‹°€eD•™åå—ÊX©[ÃİÙš †—Äb!g¤Cé¨œWY\Z7£”¥9ïæb=èrŞ×9@o*ş?ÇÿíVë€şÏjşo³1ü\€a-¬­äÿÿşO<|¦ˆ—«.zàÜ†¢ÊJ×w÷S— Ü? ÉÏÿô>şş‡µ:¬øıÚN3ƒü÷_çßßÛ¿ÿ!ú%»$ó!¡ëŸ±Y-%ı¶ş'yÜ?ÿ÷×?k±èŸ…:`óÿTÿô~^ˆfC\È‰†k8ÇÔX¢Lm-Ã³¡HËÙ,šç£GÔÂ#(Şš“ÉÙœ¹ü¬ìñ]qNˆA?1VG­ƒ±±5TM³4]ÇĞ³W		A¸˜JuøVJğƒêÿ"=(Ià›çÖF[KñHô/òñ¤ÌP;øæú·2v¶¤ÿ!ÕRº 1ıÛ¬¶RıHè?ÎIòweükë?Ö^ »İî(ÕßûúÏB[Ôú/Šà?©õ TZê.Õ}Cçÿİ<9ÀUà7ïÿ-6»½ÿ‡Pÿ"ì‡şßFÓ¶Rü/õÿ¥ø<Hş°Fûåÿ4ëÈø?c'ÿÿË0%ÿŒb¾õü%Çûù24‹ËéĞ7¯ÿXÖB—ê¿!Ğ?o7­şm+™ÿZJõÿé¿6Â³µ¡a"v«Åª	±µïpØ¸HM˜å­5a›¥–ù¦ú·î+ÿ3ı;öRş”kş°É[÷ùéÊÊÊWÛSJˆ?ìüo*ñ¿ôügˆôÁŞfç" {ˆ¶B»ÏĞÖH-Í9ÂÑš¨èkí–ÿAé…ñ”âÿ ÄÿàÕ›¼¦ºlı²»işÅ•ËçôY1ìôÓ¦\şèÅ‡ß8¶2½}ñ™}Ëäç_ùÉ¾Ÿ›¯õÙ‡_=ñ?5å[w¿üü{-ãşĞ2æ²ÖaÕ7V¼ñ’;¯wØµkÆ,X>|EË¶»?ÖRêèë·ô­ûF–…~k~Í÷ûØc>¼ä™§Üôq+uU76×¯íó~±gÃs—­&µcÆˆ‰“¯ü²æ¸OOß){ù¢Äywî_‰F>1î‚+ÚİôÖq‹¯øêÓE'OiÌŞç7]bÚôàfãq²át÷m+Gİ|»ùä«>:Â±Y4?òÓc.|u·éo6»ŸY·fó®µ/\}ó±ç·-™0¾gï–O+fM©×=ıĞï?—>[·eù‡Ï®Ÿ¸·s™uşu·¼Oï~ÿªÅ®OÇoÿrìoz?Quÿµí?„øñßÎ”âÿéß†@˜‰„9&ÌXyÖj‰²öÚ‡5„ç¾K8ÌEkÙÿ+ÍäëŸ…ÅÒüâ¼m»;=ò½5…˜¶õ¼Ónx|ÄÈmÇ”it²éÛè[7³/ìØ<qÙú'?z}ÃïÇœ´õ¡GWËÜğÖ»¾ù—ã×6şù=ß;³?ğÿvşãÍ_x}ÙßßıÛ‰óüM§nøõ°Ÿ<}÷‹[?yzÃšäòÇ^ÿ¬aÖ_¦váM3Vé—¿}\7µqç	›Ÿ~ìêãÍ\;÷¤˜sNùøÏ’Ğozşqëğ?NFÜü¤Ù9éØÛ§s÷Ç…§ßRïßÓx›û®[©¯µ?øNçªáç%¯9iÅ¨Öògºİ¾dÇ‰vûÅÓœGÌ2yÑšµÖs>GïŞZ¾ˆ¿w‡ã†q†2áòæ«ªÖ„ŞÜ]?vêŒ%¯N\Ñø¬#´tI×È—tgü©oÑá‹½±úJû¤ÃÌg]üÅÂËCM·ŸrãÊ²÷ÏW-oYw²#}ÌãÎµgŞöŞúÑÇDÿkïuÏ\Y]ñQÍ›­9c‘³£óöÄÑŞyŸ{Ï™lšqãŒ[Ú¦ûjTï	;è½›,G®î¨[İı1Úõ«Ÿnö¹øåÉ{Üñ+R;gnÌùwøÂ‹¬u}u÷š–¹7qéçÎeó+zóòÊi×ì®Y²y÷k³.ªí»íÃP×µ‹ŸûCÏ1ŞòÔEãm:q“óØï9÷Ò–¶Lxü—=MÛî[¿­ã‰ã?8mõŞZiÕê–#\¹ú¥åGŞ3ÿÒÑÿxÿ’§~®+3-<Ş·á¼*[ß#GşëÖ;ÏtüégÓ~téÃ—Ïrşöe#oe~»şÿoãÔëºLÃ?ûœº¿·õÊi'\X5óG¿;3ğ¦®f5ë´'öÜTşèLïIÿû»§yÎºÀë¯ıçc/DjÚ{oÙøˆ¸éJ×É÷ñB‹«O8¯öøİ{£ú/§½?Òùï;Ö˜g=ğÉõ²®Øu×5}ÿôA¥Ğ~êÃ‰Ó]Ãqı¼Gç^ÜñÕM¯L{m—ıí_M¬x¤o÷.÷)ö-©'şrÕ™‹n^Ù÷êYë*·œüY_íI½£ıËµ'®:ö”ËÏ~uø“#ªçîÜrä®Ş—_–w>wÅö§–Ş÷Ïº¥ÎŠ£®şÖ°³k~xÓÒûÜüöÆå[:nvßÎ»&üúùÆ;O8zÚñ{Øºuû5¥ş/7ş3Cİÿ©óßRÿ7dú×†ÂQ«e¬!meVK˜ãkY¦Æ^SÃ[¬Q§#¼å€Îÿì|ıCş·ØKùpòµáÜ–vzíÿ³wæßTïß7…Ê™‡Ìtpæ!¹Ê˜Œçš%œQ!ÔQŠ)‘1óâ˜2gÌÈÉpÌ7É§Ö÷óÃwİ»Öw}ïZ­ês?Ö:Áû¹öcïıÜ{¿ú-JMI/{Îwvé|àÛ}Kú¼Å(²·ãã“‘Õnó:†k4×ÉÇîgÿÌø‡ü2şßÁüï'éDBá@ ñëöUŠ‘D0‚À($Ã}{á;òò¿ö¿şíÿøÿÃú¿^´nƒ‰”¶j,DxI¨6 ”0Uj\^8å¦•¦x/VuüÓ²y0sc*Ûİİıƒ‘óo—Õ}·b¤z‡¶¢!”í¾›a¼c.>p%Êš3í“¢3–Æ›9‡“>‰éÌN‘îœ¬³PLå@ñV&»e×ÚŸ~RÂY‹]VĞNm‘½4é°¶Ã%±ò(6Õ2Ë¢>¿ø…ÑBz­\bò•©ad#§¥Qk©_í‡À–ÒGl>ª)6É4_HŞ½ÿbç.½ï›hOZ†	mŸ6¸¨cƒ9àûßŒ ø×¨ÿî?~šşÿ¿5ÏïÉòçú;¸ÿøAüO‰8{¤ÈA£2ÇCVjw©^p9ÓÌ´yìr¸ ”5fkju¹›ÒÆÏ'½=T@«ƒ6;â“íh¢ˆÊNğé“¿/ÃyÜºUp±­Ş¥X»Ü‡Sí©U½_N—'ê«¸·HM +Ó—jdL™Ú‰œ÷¢}N¤T›yØ®^„ëÀ÷×‹çøİ3ÀßáÿÿìÿB@Øÿ‚ş`àAşÿ/×„G!¡ƒÂ@á8ì×vğÛs(ˆ…H8…„¡pß5ÿÃ Òùæÿäÿæÿ•@	ÿöÿÚ»:}'{ì‚UŠZcÂÛ%æ—'Ì¸Zì‡Á ºÀä.IÆ¤—ÙÑÏò®/YgñVÔÔ>|æzL£â™lâsÛ:Ânö|„÷ÅH³–Ô;ÔBÑæ -İºÌ?ñóıãêÔ/Âøÿ÷“ôÃğx8ÃÀğPÃa‰ŒÀÃ‘p8!Â`ˆïºÿñíïÿÌ8rÀÿÈ`%ş¯óŸ’n§ATÌ³G=Ã6«ß LnîÒÄÔÁFM8{ƒhbãÆØ4Ä;ùÑåú¹OĞû<sº¶î˜È‹44sÚb=tı‹îW™ÿô?IF@± ŒÄa¡8
ı*úÚàñ_›,û}ùBü™ÿ0øAıÿCùÁ¿ÕöÍşÍïÂM$î“¿qtd®ø.æ`/´áö½k"OÈ»Ÿ;êÁ‡4]ÍUºxp¥ga5øUq¹ÔI?Ö4š)‘'@ıÏ,ìàşç¿™ÿ_õ' ‰p,#ÀHA!Á("˜€qCpp<ğïêÿíC@ ?ÏÿáüÿQü0q4rÏ}ÕÚº“{“£_«ï¥™QZåqiı›â/Çü‹BÁÁû×_ôóbO–ßH&ûú®Ô¦JºÓ‘µw™D[Ù9¦øù°®í0ÄƒC1—¸Œ?Pğq£!ú‘X&„”x›¨…«{}…TÁ{G·N‰K†ÛGû#ü{Ğy“}¹ÍÉU"ÛZÅiQÛ;sb%e¡g:UL?Ä&ÈRÕÈâyû±wägƒƒ©ƒÔDãIÉ$fû|©ñéÀäíˆ.ô(óµ€1-cN<>êÓWÙ˜bôšcrºãĞqà.‘à U‚¿\4Ckë™.vWD|õK’#áÄ3VÑŒ/K¨ZÃ7H‡›½	½ë•Â¡Eµğ%ÉIñD+µWf/SÈ—Óg´o¯º)[ßÖÑ²ì)>»²‚=”:õ6Ÿ(~O\L‡‹”‘zîRW+«µ<n`¶îêÕgë=33k]U¥ŒÊLäX5ŞSÎ»WºDR+ß<~ógôh„	•ã¦>j ¹yq|”q/ı¤$¡LŠèËÃ>6qàWåTÒ´ñÇ©0€İ~v]ğN²ë£ş åiş]¾£:*@Sà'Ë‚%jt!ûï\¥úâ%bßC¤!ã*óSS ­ñzêúíd0¿¬,ı|JN’<ùünev,©|šyÍ®ø•üÇ«ˆ’1ÌöË[¥tœô«®`]YæÓ¼Ç¤,í+Ùh%Šº3½ò^„o¯ÆWÖ%3İ"¦Ï—ÄÛir$¨³*q.”™µ³ù¬dlíŠChfåùÍ#Lô; ÅıEöksµ %Z¯Q
	öm+˜& ]¦™;İ%úÀ¼‰˜Ö¯ê–óg%ÍÂ ³ØÔ¡'ÃzÔÇzaö-Lj!«5tÌÍf´–O-…9bõo»)&½Qs@ùÑ6 „­Rù÷à?ôkäÿo'¡ùÿ§è ã`_µ@À(ŠAq8ÇƒA($@px$ûó?
şËşôàş÷Gåÿ"3gãE-îó¶„B±7—óNUÅ¢W ¡l—”~_‰v²k»×<ŞO··¬²ËÅ‘]ip¡®dDÅµÕ‹¢4Éò7¢÷(Y®•êÇ_i„wÊ½õgûŒŸp3r³³b\I·¹rÔ"<F’Y¨œæ¡š^Ú¥ÏÈ†Ú¾¬áÍÍ’K"DÄ‡ddŞŞµ¬œ‹.Ğ7òKN7Sl¿ã ğ©ëi(zí>rğÉQ{wjDeRÖ³¹3–Év¥²™\·h½XD›/:]6õf3µ;Õ€åÍºUÍeDÌ»qÕ‚-m?·4
Q(ÎY(DêŠ‘›÷²êTØØä'²AÕ ƒ·«ÀrY®ıëN©ˆÂì×›&·×Äf÷Ãiç
Ñ[ğÓxû$6º"©:ªÊnµ\6ú!÷ñ²U„õûÖ:rgéIüKCfå_Æƒ*OòWÔÎu+”t÷˜îP<ğpö>ÛPßiËÕWß1îÏ ó TòxÁ…ÆÛôo%–¸%_ç3K‚9ÔÙN[yFQ%|”ê§§½Û*ÍyGFrÛiÇBbö
È‹5ê¾ÖwŠV+ÊÜwè#FŸNÎù<ØpÜjÓê_œëyµ¼¥zAã…Öœ‡9ö>jä­f“XH~v¦ä‰™cÀ &;Ác¼škÍO@KïñÑD1ğÒ"§]®‡@ôé~ˆºÛD]Z¤ûù{æBcÜóÖ¢ß‰¹øİĞ-g:Šä‘;)ïfœƒuEË¿x9ÑY¼'âü‘œ9šö‚)æîéûõásoî|a0º= ô®EçœøLÉ0èI)£w°·ÌÜÃ§‰Oä= Œ&µ—t(ã›l?£®VTA×‹«­l-Ú^h…’ÏïìU×ÜHc•lÛWI1ıt„ÑÂKJ×´»£ÎÛæz‘·=eXÄIZ3õ~0>&¸ª{‚&XÔ{Ñ¶£Û`® €®nªk	¤?5-ëÌL–ñ•F	T“fAüZ­ê=÷ĞqÆ+ÏiX>IgWV.‘æ`¾0jËÎF„ÈŠ[dŞ'õÛOu7:!Ô”²î¿¯¥÷¼,F÷Jª`¼u°¾Í¡…š¥¯‰ÑòĞ{¢ğ’Ñ˜V‘ö5«ezÅ”hT ‰rìB*Ê-¬úOÉ¬¨;ñ7SƒnNÃ„ÓNG·s©ÙØ.Ê¿—İ
Iš
;“®¶
å-j¾ôQŒ+Ìİb×[/>	`Sä×÷XÙ¾îß1ë¸Èø1ã÷«¯Ø¹×¸;EÒK4d/>Z÷0à,ˆk’ËÙb{—ó0ÀÂ ^öùB0Cî6rH•)InûŞB4ê$kyªÍ,5[£*J8®©”tsúˆ·ŠlîÊÜ‹È¿ÑÏÀÌ*ò(¼ü„ÖµúáÃ‰VWL‘İî"ìêÍª™#éí·ÚƒŸYÈø–f¶p—/²øª‡SP!ÚÜEÔVÂ–CÖ¾§Š¼bOTe»ÓVn jJM.Ë!rïj†Ö¯¾Ôt6ûÊŞ³s‰şº üYãÇV‹Îe&^š/™^¸;ÁZd(pVæWg]¦õ˜3=ÇUÜD×HÌ[ôÚfz¶ÒÕÖ^r×¨¾İ¸µ«î·ÿ¸úI3 Ş„G—f-gëmb£$eºÓ!P™ÎĞIaé>«ìm×i˜NVüd|¾SNjÙÁêw%ÌÀLÇ
08µöÚ©íØ+ÙzšÓÑ¤‹ÿ½şøñÀˆƒúïçè€bP0E" P(¡`(8‡Ã‰‰CâÁ°ïyÿùZVş¥ş;xÿóGÕ)£îÓZİeu™E9C¹¿7Æ/5—ƒòHƒ¸¤4’Hh5–ô'.…aÎòI~†ÛáP.>xş¦±gsÖ3MDÉß‡Vô7ë½Í&Êı¢)JcNYÜ‰¢ÊµHE¥@ÍŞ)Åx pNQ¡`%ao—ˆûœ=Z9£­‰)´Íû«€Ş¾`»R¦$8*ĞØ^qòXxİI0-nïÈ
ËèM¥!ÏÚ6ºÚÉ6çÜ,v½¦ E¡CÍi„&¼ÓÍ¸ÍsM®cˆÉ›¢Ô…ÆLë¼®î½Kúş¼ÚUTm@ )½Š“EÇ;ó—bk¼ùI.&]ëİi	¬êÇT‹êzF¶¢º+{Ì$ËJD©xò.ïT§Èò¡–èçpÅµ„ø‡jÔ†RA=(îÑ™8àœOËywÕ»O?eWåØ~æ¬6Ä“½ã(rŞÁ‚±Î}İ;âèK”×d¯ ÿÃ÷b¤nQ9£‹ÆÄÛÏ:œ¹vÑlöOõßó½1j1{à~,£•OJÕªåòÎ‰5xÙ@*’%[ÓÅ t:s ü:²¡î¸ËÍ`ÒQ„şÑ¨S¶ê[«Ä{m%!eB²Â‡¸·‰d0ù²¶I²è¨AV³%$I²ÜOLÙÒd¨~‰r­_/–œ/§İ¼¼î¿½zÂ]=Hˆ™Î(#&wøIb±ÄË‹L¡á·*Vô]Ók~nÕ T”dv»nÀm ±8î1z ^!šúe.ßwŒDAdÇH²í‡tT³ĞºNQË¢Kü9‰µÕÀk®ŸõõÌİõÌ¦Éz?-OS'³X†™î÷&.ï@FÒ
½c¨Å½ã…õ¦à +«±¨@mæKFÏ«¸G«r.5e­lyDäm:ÿÖŸB±™‰wôšHj¥§ë.•öÍ/Ğ{Ëåâì–wÛ™³¡²(ÌŒğ°×/DÕæš¯8XmQñ¤É4A?¶Ö¾>¬]¼¢€u…ˆó²™}[&úM›·¹ä<òçêú-ğb­tE"]RØŠBtÎÎ—¦«Ğ³G”ìXÏ–6ióP[Ÿ_)d~á,7^Ø-ÍÛÀ‹Ş£îH/3y=İ!×ùodL²oªwŞcµhhÌº–B“Š|ÚçÅ–îhÕá£ ~Ä"î²¥î’©æUï,[e\àÕ$>(ö•e*7
ğ6'½ªkY´—‹íëØÚx4°`rtHÎú©©‘ËüuÃÙÈ€Z»œ	Ì,Ä¾øFœ}ôé¡?ØÒÈ#ÉA"²ğN…8³‚|ä\±x7}¶øĞzºç½ÒÅ@EÕ,§Ù»˜~ó'zƒñéf:n]½®º 8ş0?'QÌsÂÈã÷‡ø»ËhZÇùá³¬»®yBcéÑ'kØ¶—åQ$@õ•Wß–˜b¦T(`J°Éû­_V“ßîÅ½ãÚö/ö:ŠjK9(Ò%ü(8*ê£‰$!½'H  ‚†"ku×ëtAwUSUN³¸.Èv”eTô‹(¸ ~T¾`DÁEQÊ¨8÷¾WÕİY¿‘™IÎi­å½»ßûî½ï5İ§ït¹|ÔUß>øŠ­µ§­¼§ÛÇß<ğğÊççÒ×‡,]òagvû÷kg~ğI‡NOíßğè[ù¡âjÜ~Ë£/™}Ë¶Í®ë.Õ>°åà˜£mÎØFy»8²ÀY÷î5ß¼rÛ—_˜JJæètÎ’'ú>¼üN¡fQ»×ÖoòÖğÊ§ŸŸÁÊ1c÷·óŠ‹Ï C«MU;^Í±ıĞ]{Wx7Şs÷µS7ŸŞüuÑKÏÎ®}ş‘…õ?¾JÇ&ºn| ¹ö¬
_—ü+ëgş¢ôŞêå!]züĞåçWÚ\>mÙ?ú,ßÉ¡F—+¿˜S; ]^²:ñÅŠ}‰öï^¾sãÖ»>ÛzãÕ#¦øğõ¨ïæ®ó_¼­ŸÿÙáÛz¶Zu[Û9Wq-ˆôzgw·İs?Ø,ŞsW ·Û?VøŞ¶‘•ÓV­ÿi@ñ–ÿ¾°ØşKYõÀk}/Ş2êæµ£ş¶õº[¸7÷å§Ÿ\ms‰‡[?P$ííÚRüÚ¾{óX7xÂ^wÓ°ÚÔ¹]oì´|ÚëJÉV÷®âå¡Ç¶Šÿõ¬¡Ií|ú˜ä¶t$éØÍ¹óÜS“ë¹îı=ÏìGrÔ	kÚßÎw¨kÅ«f¬ÿíî_ºóæç}mÚ±.ğà×,}ãÆPAøŞo|räúcŞ¸ı›^ÿ¹½ú‘~‡5dß¦*çP=¯jûîGçQ<ùÀÇ=ÖÌ_³÷øsƒ†Ş{`±¯ÇœÓ¿ëıÔY%Éì;«;¿0ã­Ù'İĞqBşºû‰e?V–½½dàùÉg.ŞğĞm·ÿ³r·ëË¥sş~ğàEKâ7,ØğôU÷şxİ{‹Š?újğîAFo=7î½da·Y½™õ}İçáº½>ûkÏ¿şåÛùøUÛÖK÷Lô·Yñè7}înuE›§v-˜Ûy£ZT6ä‹_†ŞxpÁÑ»¶m.éôyâôşƒ^/?¼mù>­ï×ÛÜ}‹rÍyáÄ¢ûÆêÇm?r¯û°ø¡Íg)Ó—áèÏ­÷ÜûXKÿ7#ÿ+Ì?Uú¿-¿ÿö'é¿°¸P
øış—æBAO€úıÔã—@)%!_AòzóOèù_§Éş¯¿%ÿ?Iù¿ÁÂ†~¬ü>ïİ«†>¾­ŸP¾æ‰³ó*ŸHì¸cã÷ìßé§ég{·mi·îzï®ößüNèo,æ¾÷û_¼÷´vÙÊ~Ÿßï÷ÕÚ—.íşİ£—-i]ùfçõ?L[·S8íå•_üxñÕÃ.ºÀí?³ëGÕ#>~á!GıéÂ²ó¾î²î¿ï±êÜq»½=Òû²[=×ví~hôz±r÷âÖÒißœqÎ¹eKZvèNªÿËJH=%¾ÿço9ÿógè¿X:UÎµôÿş$ıû¨·Ø_RXğh¾Xâó)õùŠò}%^_Èç-öæĞïÿç59ÿ•_Ôòï¿œ¤õÿÊ[ßš²ÁÓáÕïï~q×šşÍ:²µH|üÓ}‹ÚúÁ?Ë¸ö®m°Wî{ÿÚ×Ô>~Æ‚õ3¿ÿ¹ìÀÓ¾®³’szä¹Í¹ÿ¹ÇÃcwïÏ^±)ñÜšIõÆ¨[ü.ÿ²úòG/~–{~íæIû»>õoåµıÒòiÎ–Cs-{©cô«áó¢>êœî~o^«Iã7~fúåÃ¿ŞóÁıÛ%ÑåŸ]õÛM–¯¿¶â²öµ¯÷uß—õïuóö–Ì}åÆííáyíƒ­î7»íš=¯XhÿT¼ü®õgíØpáÊ«6ı\ó—W;9ó¼Õ¹sçôœeì/Ÿö)Z³ ş³¥é´oŞsÑÃ-Ksş_:E¾ÿQĞòıï?IÿŞPqA ¨Äç¼’Tàú‹D¿,öÓâIÌø|Ô_p"Ïÿz|…õ_Täo9ÿs’â?ÿşÇşğ|ïƒëßº-¯~ÒàúMäÛo¶ş±ÿÅ/Ék´1îpëê€2yÅ­£–Ş>náËF·«}•±ø­‘áú%sËè'ZçÛ=ßîØ9û¦›‡:G¼‘×:wß;‹fûäÙ7'/¬ïı`à²ûFtŠ„’9sv=²ªŸP´äQıÈş+öŒìÚ.O_zpşè»Ÿ>gŞŠ{^ørÌˆÕ«VH«ï¾j“¶è‘=¯›ø^¾é´‹Æoù½şÿ«ê”?è×ß~Oıç-ò¶Äÿ“¯ÿ˜Fb,IÆD#véb4¡¼ş½…ô_èñ·|ÿû¤üuïæÈŠ[İ…î¤\!´i E=¨É1ƒ*©¥šJ’DX4ˆ¬1 ÆÙó %ü·{*€@’¤ˆ„45JD€éÄŸş%Qªëbu1TÕaGXG$À+$!a¢¨ŠsÕTš1â€+dPêqY©p0phjL“ñ7ãM¨D„ *†„é†#FØ"ÏDªªˆ`ÏˆßA4x5Ÿ„d|§{CW°»ÁEÀQœzØ©S#ªÄYGìY—VVOPY•áC¥ôè!Øhşê ¬éŞ<{V?ûL¡—p
ø¿)®åû¿ÁÿY³¯¡ÿû½E-ùßÿ:ÿ#b$B%Œv°+b¹éØDÔjâQ
.ê"# Lşí1à `œà`2 şñ9Òh­3&j:%N§)üñlRæ–h­[‰G"ÄWÖÃ+ ZE°‰5¢¬èF)hD§‚­;©ä?rnRÕ‹Hr(DÌ‘,\FcF’¥„×ei8bc…¾` JDO¡Ê±@¨X*,ñ‡””x
„, ¯•!’TãL ÈèFM0Ù–¬¨¬dœ"ß:˜Æ™¯A¦. C‹C°f“`¨e¹4+‡«U	É5 €ªF˜uWƒq¹ˆ½ŠJ²ä°•7İ¨¦¹½e=|8®BSuÄ"¢Rµ(Å²b”T‘Ùµª,5GvoKkÁœ È;Êœ e6"I”ÍFık4¦ê²¡jIMÁÎbU6Ø«Ä‘İ°)Å`ĞDŒ
ÃĞÂß=&ÁœÂ¢ÓÀ"E ¨Ô¹ÕrD‰¥Œ…ß@ vÒ­”ØQ¢v2-İÉpÕ )ÔQC$ §PÄ¨©q€.‚LR@=à-aªQÉ‘l ÿÀßÔ8ˆZr ‰©p Gd´"•ŒT# Tx=Ù:qÇuy¼¡å:ˆ.+Af’Œ·©qQ£àÂ°Ä‘08  0!à‡È
*Q]®QÀ÷$NšK°±õ[³g§3(Ã0ÀéD]9U%’„k|ç‚ğJË‰sÉ²†`#dXÅÄòaÃJ+i§D²Çç5ãÇy²É’g0Åè1+’ëÓgÜÀƒ„š¦j½H9„¡(X ]C£!H	¸r5Zz<-(¢ÔÁà@ßQSˆLwI¨Ú®ØU1&ª
Qµ–²U± Èecd¥ZY·ü(\(£æ˜~9Ewd!ïPø’Š¶‹wHdÁ`ô†ip
X	è%„døa3ÈœW@ÑØXTõ¦#r@¶DXµ1“¦(@İÁÍŸ‘ª†B`ÙHNJt:³÷är¦[ÚvÊŠDëPçŒÈ”îSÊu:[~RşÔ¯ÿÒ	¯3ª×œ´ú¯ÈSĞ´şk9ÿqJåÜ±Ó¹‰¨5©ÄË§ÀHòÊìT¬ş2²MYG+y~ IŠ‘É˜‘‡ê-clè@ÿBÕÈq³IÇ®3¨ª±Iı§Ñ€¨Ó“Xÿy½Më¿‚–ıß?Áÿ+ÔXR“kÂÉTËçñ:ğ¿ÅdH\‘URA‹QQQS.lO[Œİò.¢Å2Ä
iäH”‚Ö 3fy«Öt2Y8Xb)™Ğ§’%H ª‚ *Kx‰ñ`4ŠËôXMÊStLÂTô~„ …81½›•å…L…gã1
01Ê3c¨ó ùIˆ:æ×S('	Ëİ,Ÿ5Òf‚/>8·ÉlœWs‰0KÓá1¾gÜÅ59ås-²^î{mZRrQcrĞœ$±êS91ÔJ£T«á‘-[¡uF¶E“b5Œ@/ÏEK$2S	”5ªÇ#æü)ÂM4$DdS< ˜ÕU‚`>+E¬‚çˆKíY^;ÖD,öÙ³ºÛI)ñ™)<c§Ô®Ñîdİå³›…27	­GOFjD‚­…X¹=‰Ì˜af¶ÒÆÔ,©ujñ˜‘&Z¢OGYyp¨R;L2èÛ×İ3W°õî-àÿ~«Àâp4ÕÅ fØÃ1§çùµDÅˆe¨XÈeè®¡¡À4‹¬V€QQø°dUê¸¦Êk÷}Ç •éš A'‘óŞ3Ù0a9§¦ùœ1ƒL‚a•@åMìÃÁeâH
§È–*f²zA7q„âˆ"m\œÊ¾d¢¬Lä·\[Ø"KÀ¬ÌÖ0’¥ªBA”LàÃR$MJÙT‚ö¬°ì¦‰¤éå“Ğ£›'¦7Õ@ğªµ(,WŠSƒAfØ¼"`şqÃ¬‡ ªnqÉpYµ’Å;¸–¼/ÁRJWY­f&1hš¶;ì8aÙ;'Lô6NJ,ıdM7]h&”»:”“2¦û1=ı×Ìô´×eĞş—ùÀgIÚ†ß¥°¥‰äh'	¶æ4gY‡×¬ê¬9Õ)aÇÜÃRºíw)ÌÆC†é®‚ÈŸ˜„!£Ç5Î¦Ô–ê˜Ä¨!NJ²O4iºÈ2«¼êÒQc=ã{›Ï!?C	÷´F„aÙà©[šû´11”VTè5N±›`r.É = FÅº¯Íæ3Öã,¡ñy¹Äãm9°r•–o.ŞÍ$z,"9îqŠÛa’çÏ^a{i¤%9)`æ¸zæfqÀ¶±r–ñ×,lßøÜ\l"§C:ÉÊ :Cè,)Í4‡²±(+ëŞÆ[#«¬ªbRäØâŠ,ı`¦Ğd´X¼ãM²ağÉNÇ?{&Iö¦ñ&³SÒ§Ï¸#*&>Àlé™e‘¢5qQ“ôf×ã°Á'@ÁÒËdFgR£	ìì±>eM¦Z·%NTnÜØãéIF(AÚxåÀDç í&éÔsŒWDÓÊ@P*®$¬Cr¨ÌzX¼7aLBV¬;ÈC…7wƒ  ‹©Y&†1ˆš·Á$Ğ
n«­Pnõ¸n^ód^dªRó©¨EdŒº`KP]êlæÑDŠ‚àOßp@¹°…`«£Ì€ã¥E«a‹°NšÌ„ Ğ Ö}Z’…“ƒ(bÆ
ˆ§PCN4+ñ!ºŒ†ÁÅ6â[,2yeQÛ²Üøì`û¦¬Ve,!FËŠ\¬¼¥ÍEË-–0‡×æ«İªÜ`šT%3E°Ğš2ÃªUà7*©\_ ZÜ™`KêÖÌä-Æ¸Æê_x)¤ŠR³ù¥È‹¬C>,Œæ)6@²ÌÚÁ;ª,Š[}Ul{‚yçxs‰ËåÂÒ½‘¥aÄdbD'Êˆ•œ`Páp YcÿÃ‚¹ŸÕ¶,¥Ì'ƒ
MDóg“ƒ
ãã1«R1Eòä‰—™NÍWxplÒÈ»x[¸ `4°-«ÀuNåÆEÄP,5gv”Y‡XëÊPÑû¸FR$C ’b	"
x0Ë7„ß¯I•	´qö”ò¸+•Tš90a”ËPD`ìØéVÀgr6»Ç†)“G°¬dj49àÚ`.a	]£æØæç8`İìD›eô&6=!+“3ÂM(®1ô¦Ë9LÉš¹¢‰ƒG¢XìÃbLO:v{ĞyrAwP™n1;ä¡&-Ja5²uÁõB47×LÛ·Ù`êt:û1Íp›™;#ëkp£ğ3ñ åÍr7zÖÌ˜Œ§ø	´Ô‡ôo:ÒñIÿk20s\€‘XÑ`¤9Î}n&õß"À´ ­u^ÊÀzx«ÓÊË™¿@nHBrß(ãFİòˆé˜ÄæôgsB²Â<W=ã^gÎµm$ÅŒÆÈŞb#…¹ÕÖJÊğT0¨ÇF45H–1ÓFQ—çĞ&¼T ŠD¬ÿËæ^&$ÜšXC…şMWãÅ!@èF#n¶ ™À¥Éº ¶_+YØ^G€Ô1.€g;H:iÎ`òf/“_SbÌÚÅ×V	_öY?Æ
Ç…‚•şı?ÚÿÁn^,®‡Oh÷÷¸û?>¿·ñùÏ‚BüıŸ–şïÉìÿşŞã?h0,Ø5<úƒG)àİÚÀá‘m#¡«±CQ< Á»¶<5ó0QI², <M`V%Á\Ù$k6İê°5Ş<‚æ¸H$ƒÖt«õ÷¶ˆ‡c6`–&x` ,ÃfÒ­‡y’Á°Œ¤šÅWV;şX¾So¬ş!
<Î{°,‘RxÃ*öo­ƒU)^éÔ¸á¬V*xXA4dÈËLÕ¥ö»t“vôƒQÀ…„éñûXêA"#+¬\ÌÃ"JPg@dÆ£=æ¹DÃÅDHŸˆ
RÅõ¥ÌºÖÃ¢nLÂùË
ğÕok3yìÓôcÅŒè3÷$ùFö²Q§öÑ•—ÛI;Ñ!ã.ƒZ9œÕ.'€w©ãZ.|"L+ğ”z~ãŸ TYšM²%‚u›0'b–_ƒ¦ÆØCó
’ÊÖ'<2”Š=º, ŒO5Óº“Á òˆµ"Ã“^©¶—9=4s¾ OAÍÓótl{á±S”8ˆç)Í$Ûj@¸2ÆZv¸oŠm¶#Ó –éÍ Lçr5„ı„]Áö˜±EÚ2AÀ~Ñ¸{§tDĞbŒdO€ñØça¨°gÇcìYÖ	ÄLA°¾¤};_•F…†‘•R›ƒ¥¦ÚÙ,Şbôâ‡yª`vÿO¬ÿq¦Ü¼úwı/òäç7^ÿ<-çO©ópŒ):‰+¢~Á+s±ÆlCRÜ7iæ °ö?í=mŒ$ÇUsöaØ†»K„MP]ÏÀììmÏç~8ë›‹Ï»{{+ïÇe?â»ìÇ½3=»ÃÍtïMÏœ³ñş$Š)$ñDşåH÷‡€¢‘ Qøa‰$N”€@`á'ï£ª§»gn?ì½Ù3×mg¶§êÕ«z¯ê½WõŞ+«lÕn€Zi–¯I7`OTM  /
\ıŒúÈı.˜qõ´<ÄÆ})øbĞ_|şq¾”"iƒ^¬¸äZ,Nh» ««J°*ßÚøa§Qğ0OìÀ"]5ñğ~µÉ±“¨Ü¤ƒ¸ğB°÷À„ÊÑ±qo4Ş§šİŞH˜Ø:íİ@ÛT‰Rîh”‹´¯Q‡ón}gÑ±ßî{Ûk‡7ËŞá-ä}¡Â2·À©Ç½pˆ5É[R)º3JlÊ^ ó2Ó³ãê\šœ#¬ ÀÈ:
Lş^ĞUÅe³jµvXËf7d:“;¶ ¾CU}ŠÆı5üµÚ×òü/´yª¢ô¹Êò> Ô‘Æ¸#dƒÔÂV‰,ê}¨ıqàwæ\J•ìœÄtº!GB†Ã/¸vçoÒÕÍ6*„»´Úİ¨¢­$á…c/'x_Ñ”ÖÅí{Õö—Miaİ¥v¸h m˜¼ûk
ÊŠŞÊ°WE¯ yı—=-ÎvĞQœ˜
Múõã+€ˆâx˜š»ô9ºùÊë)å¦á«HÎúª­, 5³ô!qSèzJ‘|hhH\âj~Xb€UÉë€EÓ;H}¿+ñ ;>îl[hL 3J.Ã™‹ÚK:ÆÜPJÂ\VºdËQ{ç¨öWÓš¥E}¿&…®‚Kã‘=‚ğ17ÿTBÔŠÒ&gŞ¾$éÌ–A]7Z
ÿ”ßFÍ¬aÕ U¦Á ×”<™¡aî\Š´õ¶m$¼s­Ù*©+ñœüw`ÜêX+á¹‘PğO½Â­‹D Õau²´™êñ
ÓÛyF!‰…2V¸ÉpÅÕ$ñ1‰]` ºŸš›¨*w`ùä¡À¸1yxÜ$[ğˆù‡Â›{Ä”’ˆ,”Ğã]±¤Œ(†éêÇÒ›ìáˆ–Pt”â)qN„"£Âv‘º‘TU’Şñ»¤{PlĞ8ÀìI*öş
ò¸T
¼P§3UôDxå¥»ĞoRi¦ï$û­‘PaßƒÓÂè’2á·ÃÂ—5©ğx·0ö¨£Võ®Ğk2uÕ;Œ¾† ¾¥N1¾çÕÎ&®Ô E¹*Çÿşı)-°8ñ–
Ü	XÿğôÜ&„›`mo?w•¼I‡[“X"¸œ3vr!IwA[½İ·4¢ç-œÿÀâ­‚^-h¯óŸB~<ÿ3Vˆò?ÜSû?’5î´Wä7Ö²}G&¼qÃn5®´İƒá7Ãò†!Ê˜SO—`äq\UÜuÚÍ²å‹÷I¢MsÏHjnxŸNmø‘Lr 0ÖñN§KÃò(DíÓ±X³å/$Î<4íğü9pBe—ëmvèÂ¨pI#D_­5]p: ’ç; @G¶^+·Ü	²Z8p¦ô.ÄÄSxS–
ÜFÇ_`/ÅóÊ6£©£Y$·Â:Ôó€ÿy¥S]‚eÿ
Ç’¸#±e<¶æXd§•mé#lĞ2à:9ıË$±÷ø‚?`ˆ››ÍJ³åÚ¦mU§Z5€«Èë7Œ8qe™âÌÜ–:J–¡³Gå:ØrÕw à¦ãÀU,3íÙRùáD,'é!6œ"W•q-½a^ t3Ogâ"3,àK\Ä3ñš™™§=âeD:-àõc‹örN ½Çá›ñŒ®RĞNüíl£Ûrœı.ØsV_·u‘ÏÜ1`Û#ğ3Z|€1Ì@ÏO¿9#ŠE‘õ!#ÄPJøtŠåÅ'¤ùyVX´ğÏ¯®\\\*ÍNM/¬ :6fÓ ¬¦‡Î­§ÒC‰L€Fb=—ÙNb×è¨Ç¸î¢/:€Ö¹á›7kJüîÜ9zé.oJş²Üß§ü‘ŸíÎÿù¼mâ÷’şèD§}†{ê$I;Ú@HèÎÓ#^˜ÖëƒäŠé/ìI’`ÄğİŠKüU[JB)´êìùÀ¹,ö^iŠãøB”SĞóNÄ†É’
ßoZ¶Õ4ë^8èVAä	Öm ‡Ñ”î¸Ji8Êõ]iGŠ[ËÒ+¸ÒŞ‘‰„î-tìäh(ŞÀ”Î!„¤DÃt$DıhÛµëÂ(«(Í<½&®åğÿ™J2Õ[7µ;»{ËşsÜ–qøN {åÈ†×ÿB´şß›öŸ)ğ$?pöB{ä”½Ãâ0¸wf»*àØê0!.Š^~e  /ªˆ´¼C›ÿ´Åz·Ú8PşïÌÿœÃÓQş×>Ó_m±=ıùÜXDÿ£¢¿Ó¬m‚L8BúŒfG#ú1ı9æè?¶KşLö¤ÿèxn<ÒÿúñdóæÆH¥Z~Ô,˜¹GÕÜûŞ—³ò•Góæh¡’µ¬ja¼Z°"]ëÿ¿şÇ>G¬ÿñı/cùèş·#¢ÿ¡-ûonı'úd‘ÿ´şGO_ç?¹±ıÏûù‘±B´ş÷‘ş*Œá®ì½	úF#ú÷“şìÛ·dÌò47Şÿò?÷åY+;Më*úØªí|¿a5]ô´*r6½ºÕp*üEiå6ğ( ˆW`¼AİÙ4ëuL$B[ô®*¶&c»uŞPĞ¡™v³¿nµZÛîD&œ·ÕŞH—F¦üœã\3[+SqÊ×¬f©İ¢+?SJÅ¿·óD¯m‹!miÑáBQø@kå¢ö¿Üy|ß!ÚšôôUi@h`¨EÁàµö*Š.•Y{ÏÿÉÅùùÙ•ÒôÔìÊüòLŸç?¬ ]ößX4ÿûòÔl˜]‘|¿ëÿtÇ]³1wŸÿ¹‘\øş÷ÜX>šÿ}y¦f—&áãø7p9ÿâSÙ¿®ü©úŒÅ~î¡Ø‰ş-û-ø÷àOáßOb±Ÿyõo¯¼´ş+ßxï»0ùzíwœxÄıæ?ûY\IÒî º<lıëÀŸ<ÿêåøÅÏ~ùø+ÎA8±Ø_øÁç¾ôíïN>ù{©—ıĞ÷şêµ-2öKõÚFÆÜFWÔ|fŠ4T?b~¸§?¾ñğÂ©«÷Ø‰ Ücï}ì£bÿñÎK§¾uQ|bpç\êùú+ÇŞp;îõzj néDòÁ×$¾?Â}èÏoÿä—oÿè£/¼ë÷S¯ÿË‰WŞ#âów±‡;p-»ÕÜá„Ä<é¿ÿê™ÍãïÂÏÁ¿}’á>( î&ÃËå­ÆíÕÿüá_|õ+«ÿ|õÔìëS_<y6öón³Lj9Ã"<3âÃô]W}JxÇ;xâók×›_;6{êóÿğí¹o4Ná_<û½µØ	„WmÛet w	èåLòwGº­>%¼ƒğÍ<ıÈ•ÍÛ_™øÔğ¿ënêÔë<4fÇŞğlëYË¾¡0¼œùÕÕGJ;­>%¼‚ğNÎ|©õÒÿuÑúñ'?ı™/?ï^üúw–c';ğJf¥‚0ÎÒÉGo½ˆŸïzí%¼3¿c/¯}öG¿ñ‰kÇ¿ş‡ÇÿI»ù¿ÿ=3ó™\ì”^pcùÖGşìl}¦ô—Îßÿå?xÏÌ§¿ö?¯Şçë¿/¸¢ÿö_.—Ùÿ…l~4Zÿûñt‡Ò?¦<\•SVÒÇIÊ¯n3óE×F:äÛ\ÿ«:÷„ÿ—¼ÿ{4İÿİwú[¦Ğ¯¾¯ÿ…±l×úİÿÛŸ'N¾µu—Òƒ¸Â0øJø"¹ÁÀt@Å.&Ñâb3BbÜ%[äxŒd<I¹$U8"%\p0”Lã"‹÷k¶˜%ÛäŒÅ˜Ù‰#ëğZZ§J7S«˜ı»e5mW¶ı¡ğÕèŒïSPy(½æ˜WñËoFbªkşwì¶»ºşËyŸëŠÿÆÍ~ÿ…1’`ÿ÷=ÿ›
÷ßügÿÿ# 20½¶J-§„<¡C[˜~jzáƒ¥KçW.Ÿ©Ôš¤ş%1CK½f_FU$²©gT¹Õåé¥¢ÎÃ©«—“‹Š	$=ã³Ñ>óŠN-,JÊBÆ,®¦Å1ë?æ,åSœø˜”ƒ3Åhkâ4Fö¨ÌeÆY,%sÔ”ñ Âp—ç:gV+Íeğ c|ÚGP>dnITl·aº×C-™Û-ê
YÊØÑZŞª•èôGÃ›ŠÏ‰ŒÕ*gd¹tEõ^ˆ³g±˜½6w³è¯L×UÍ²Ud<³ZHV1¼÷®†Å(6©&’äÔb¦¼NŸI=á£‹ÄÇ]sëx¥INÛ¾VëtÃ{‹áµ²åuVzº„Oeï>RC‡ğCƒ¿»XøÈOà ãø±ÅìON/]˜›±D½¶!,MùùÇA~]˜œ[š.êº6¿¸º°25\™ÁÑÕ5ÂMöG‰Rßcfíb¶Úl:ímL‡M×}¶"ü¸u§5âŒ]È~ï×…a]Y/ÁŒ V°c>Å0Ü- Ğ$äã4.Ü égÌ(l£By»¶0	LÔ’Œjya˜g>ş…¦®úñ5mººZq)»ˆh‰×Hû
ÙS˜øz€,-!Ì¯#{Ï|Û’œJ§ÊWœ·‚øaËİs-!nó³×zbqnêÒSS<™vh¤.
cZxİéÒb=ñ8İšÍ£7::Ú5šŒG¤Ô ¡˜U‘OÍÊe /% ”Dn»Œ7
UÛõÓªìfSdSzo xü'"“…³ftÑ[•ë“*”.B€—M³¹ÃÊWggÓM‹P«ªa Ãmkš'ÿqÿòîÊ˜=ä¿gÿ¡‘§ó¿(}¶ÿîSùÏôçıë#§ÿè8h€<ÿÍg³ıûMÿğùEŸè_Èsşïl!;6Z ÿßñÑ|¤ÿ÷[ÿ×8‡a©b¶Ì(úƒx5£kğ]Û"ñœÒ¤né,„w•‹u¯î"}eIdÇ³Ù]Ë¡ÈB}ä9”Ä·& è•åÌ‘\¾Õ£"ÕÙlnûêô*uËÃ½îlî‰:”é…9Èú]Šu!Ş¬áÃ…ÕcFçÎØp©ı ÔUr?8ÉJˆİN¯°’·¡1fí CĞ0¢fDøUQ€M¡Ğ“Øi^?Òğ-É¯'tT‰®×²šM§	À½ïÅn ô~¿@‘`t¤üˆo÷ç´ÌÅ°|…zÍ£Ø"4ŞPaÙ%Ç.JXêØi’+¥½ÔM%dpu¦Kå{~¨\ÕĞğCŸ¼4ıGš*´çŸ¸x­W	ì™Ò6ŞåX·<³Ö)õTºiF–N§Ó8Ï¨‰’4gK•ĞÉ‚¤÷â\ÈÚQğ–ÑDhó;0GçKˆ^**Æ¾„×¦†‰_×ğò¼†å´[ÅB–Reñ-*§CõÍJ£f£.ßt•J¬Zl&])°‰ÁÁ„ü.‘K¥äïdÆt~	™lüp/'½ûP6nbâ™40²Çâ<æ~Ã;¸ï²6§ùà?Àªá/Ê¶fdmËÌ™&n_vG™°»~a(ºt~aEœŸ›—–f?òÌô²X\b(=$V©ÖãÉ_KêJmµ[|Á¬<a{‘‰‡Ù…ÂXĞ·š)©Zi»»ëÌçÄ¼Ëùƒ|I‘‘RÑVîaëa¿˜~éÿ#…‘ş7’Gı/76éıx.,-Î‹öFÛnµ'r#éìˆ†›v‚öâˆ+4miuA¨İN™nD&Î©é'fÏ/” ÄÂÊôÂTÑvlš×f¹U»a‰ğ©±ÃóW¦p‘@ša4«"sÃlfØõ«•ÁµÂÍiÚäâ¥+"`–ŞŠ	¼#YoB©W	múò¥ÅåiQ Ë´ÊÛØË•¥+—ga]Ó{TÑ¯j÷ÏüWşv÷ÀşÙùB¡Ùÿı§ÿİ‘ £?îÿŒr‘ı=Ñ=Ñ=Ñ=Ñ=ÑsèÀÿ45	Ø h 