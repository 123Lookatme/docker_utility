#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="3685295517"
MD5="f97c8f0dc40276493af01702a8ca1abc"
TMPROOT=${TMPDIR:=/tmp}

label="Newenv pachage"
script="./init.sh"
scriptargs=""
licensetxt=""
targetdir="/var/lib/newenv"
filesizes="5581"
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
	echo Date of packaging: Thu Jan 19 15:16:51 EET 2017
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
‹ C¼€Xí<ıwÚÆ²ùÕú+&2-&9B€ÁîsJZj—[üÀnnM©,	£}Øñ‹ışö7³»úD8n›øöİÇæäV;³³óµ3³+ªê³¯ŞjØvw[ô·¾Ûª¥ÿFíY}»Ö¬Õ·wjÍú3İØ~­gOĞB?Ğ< ükz{øùÿÑVU}OWŸBş»Ÿ“c§±İÜ®c½Öªï¬åÿtò·ÍÓ¾®ú³‰ü[è²òolï ükkùõ¶ù\½´lõRógÒæ›á ºÿ‡ƒ££îPòĞÓM(õ»o»ı_'øäMÔ7m=°ÛG¥‘¤Ğ×®Ì¶|Fö€kœëÎb¡ÙÆÎ5ïÊKÒşàø¸Ó?íI€fÀ›î™Z`èh–mz°eÙ ‡gÚ–—·`˜S-œ•*ŒLÊbÂ£(3sîB¦‡ÃÅÜÇ)Û”O12ç¦ {:Eüì‘u×šgi—sÓÏâd€i
eqÎ?ğ76æ–è¦ü+Ì-û½iÀÌ’%ø’,I›Ã³>g§ÈNWó|s"¸¥¥¿ı§¥ùäö¿[k5Èşë»fsgwí½ÀÚşŸÜş3ú¹UOdBšo‚\ªË`ÙYš[EâFU–>Á>TöéÇ½Æ½,û3kˆÏ¯^±Êì[Gaê3¡˜÷àPæG‹ƒ À³->R×(öé'ı‘”L°!p“ÍòÁ1]ÔµDXB– |Q×³ì`
²5Ÿ›WÚöàÿÂ–ùú_ÛX&:éEÂ¡ 5}M—î%ÁSËF-³us«òIÊqôA–l¤ùèG•ÿ¿¸;ï(ÿ5~Q‘6zıÑi§¿ßm—êÒFšKŠHXZÓÆò‚6Äj[H²bé_\…be‰Í¥×ß?:;èÊH±Ú/8Œ^V± ¬f¡Tı"ÛÑ.“Ì7_´ïåìö•šX</š°€Ó¹võ§x³Îq™‹e†E›
nŠÈ<„ş‘h0	bsÃG±Á):.ÄÖù²tãÓ•”ãøÿy0:=è1|ïõ:£G hèœÀğ´]_1èŠ°âÆwòŒVF¿ôNV!CLááˆÖN<+ÄÂXm8¶Iüf›»· áÃ 6‘±ó9ßŸ5­³pğñÅèÛ±[„‰Š(&mÒôÔ;ägÂ­‚zæp~«öÇ ãßEášÂ[1)F}±(©ß¾Ÿ›İñ¹?ßÑ—
ÄÏ¨^hf:8#2O¦ÚÜ/éùÑÔÃ åÒ<ºÚ«Ğ°vi»â(%r•"¦Ûfpãxïóğ¢ûq8¾‚÷å.+¡\Ú
ÜÅ1Ü%ìVR_§P¯”İQ÷•µ
N+»£³£ÓöïÑ h¼ş¶ş»ÔC\¤ „’áÌ+ÏtÉ9É¦ç9Ş)áÜÒƒ»Ğ¦óÎ3?„ª²á#(Ã$Ã¾ıŠˆB£"ğç‰ƒ»;ˆ(È.çÀÑßcôÌHØƒ1Ë…œÁ ³)Ï*Ì^f¦NâëáÎËÕÅà]Câ©5L¯-ÛÚÂl“`”¸öà'˜859Z¯2®Ähå¸¶Šz{Zs®©bfk¢ö§J†	ËĞ(ú`îÇâ_^ø/·Hƒ*øA&x6AÖ$8'öœM‡!Gƒ¤¢  Ÿ¢Ø¤A+¤ñ9(€‰H©¢øá%öAiëÊD	`ß„÷T"œšçi·‘ŒüÄµÍtm(~ó=:3”È«”ñg–-+m:˜-0¥z%öÖ¬)œŸCI<‚vJŒÇ¯ ˜™vÆË ÂZ¦ãWñ>î™Zì#sÆÜy¡gC	İ®ãÊ"á‰%Ê×èRÆFrPğ€åOŸ<Í¾2¡Ú;éW÷Y
wÿéSuÄÑGÓ6îïËÌV£Ù,—A¥uêq³ìÇ™›¤wrİìš0~‡‚©2‚£é;½şdtöS¿{ŠcÅÜ—e\™j•w˜! U´®ºÒ¨HİöF§İƒ	Nøv0üe´zÖ¥h4Ê‡ÊŸ$ƒ»¾k(ÿV* ŠE;[[`µk¯¬ï­Æ+ëåK¨T^1Œù#üYŠiğjÕZÉ"÷z©ÓöQÚÊÙAIŒ,å—^!GÃ,;4cG#†ËUÄ«ÖwGX‹ƒ‡X–Ë5“¨·\
ÕJ[¾ù<™,¨%sÍ«3*S%ÇƒíJõè€k¯éñ-ŸÛİs´Úÿ¿×”ÿ¿¼¨ÿ-1c”6˜9nÄ{Ş†IAÀFg,WfKäD
+ êV°©H¸rÄIz¶nÿæõ_‘Ç?qı§^oµêQı§UkğúÏnk]ÿyêúOa—Ê«çQ¡açƒ“ÓŞ ?ÂO”“%éypÚİªsFõ]x3ÃÉpğîş)`:Ä¿ƒá;xûswØ…wƒ3xÛéŸÂé :@gtúİ!DóD±Ä`g£.¦]muÎçWÃ*¦Ï%iŸ¢'
S²¥cgš z;31_‹¾‚sëÒÓ¼[ôêsÇ²”0	J!©3½éuG_Ü;Ì÷tÍÆ©õyh°ü§¹±#l+«ÇeIğ´êZ:jZh,ÄJè&MdËaDù·¸Ìï]ª˜+zûZ›£ËV¹sM§á"qMaÂ0Î»uL«`‹ÀbC.Û¤ö÷·…ƒ\²l¾÷#¹À¢l(§C\¾ ¸a=²¦5d*:£ĞJ#î]Ù„–G¡	ıê	oiÁÁÌòIÒ¹Á´.Mq5©2`Šé»0/‰ow»„¶ï¨È½)Ï!@›Ï)‘¿ß2ğ ™=æAC7ØZfin£d…¥Í-Í‡Àa' @”V+Û9C›a¸i\'¤Åœ)|®‹a‡çopiîAU­,­H[™ÆáîÜ”’¥VAä2–²™—0QTã\chlÍT²9?ôœĞí#1£ú*Mõ€Îp¡ìcè‡ |n¢ACß%©ƒY!é}d>¤FÉŠy5ùJG1ˆú•g®‘(ƒù$ú{‰«¬ùQ[¸¨ŠßÕ¾«í}W««²O¦¹¬È’œ+ÎòJ\¦V—TyÊNU*‘±÷;‡İ~ç¸Û.uû¿Ê¹;Œ¨ROcWtDYNà o““ÎéÏíÔ„N÷‹â%ºÁ!ëŠHaµ5‡×ÙJ[há&“GÇÇW¤Ø¿¶TŠXé§³ŞÑÁ„EÏ”.¤’pÄ/ƒaáÎ½-+
s.`_Hæ
·ˆ„ø„h)%î]QÈ=Îú¬6YŠ>Qê¢X•KÕ„Ê½x¨ÌØ(hË({Ù–Ù±ï‹Ç1 Ú¯
 x,V-DL†ÎW”Œãˆ£jh!æ‹äÂ!´ÑõùŠ8hé†Œõæ›ÎşéHZUû9D7a²åTÓ¿Z­æŠ8ÒêoËìÏÕ¬œH„ùjNJ•‡jNõJâ\:Y‡¹—Â±ª$EI\Jk‘² ñ+QUàÃåˆê¤r¹ƒ5V†JÄ¡íÖ9“Y”iïcéÒÊ9S[nBZ@Á\… T¡fUÎˆ<˜ü0ÿS{ŸíàÖâ„¶AÙ§ay¦îg™$í‹ =yÚZØ³ULX%8âH£Jì/îà´32Í"9-Ét,	)dÁè’¾ _ŞYYM2v+2á6ç»PUX{lQ<°w0œÑâe\!Tùt¬jÇŞÇ2K//ÎÑbŠ4Ù¸=¦çaâºX–5_!²6ÇÙØÈö8*r,ñD±•áb¶Î|ŒaÊÑ^\¦CŸQ*_áÔ@„³ÄBğ/Má\´ã¨:‹WÈ[1vË›avu9…îœvû´wïÁ1K1¾?O*Æ/dæÂnq½è‘•~,&Ï¼ñ,Dzagu›¸.+Ù/^­Ğ­è¬ÂaQÊ^$Ëacû…@˜¢Ğ!ÁD¨(‹'ö?QÌÄ7ÔÊJèóq¤0‰…EÀK6Æ±¡Xã3èHùó¨"õÏcKŞ/W1–0³™‡EÈc4y¥7Öbü<ÂïgÒ¿h
-‘A¨ÖZ8|¦h§U—ğÉ 7b:îãƒC=rÒùy$µå-™Ši¼€&m2_™Ú3±UâL*+÷ÆÇ`me4`É¥'[:æ¢šê€g›Zé$ëîãÔÆbÛÅW.¿ç©x¼ƒ8g+måN+!ÄÇs×şâ¹ƒ‰ï’M°ÂvÁÍX#Òô…Ü©jqŠĞ%­ØêÏØÑ «±ˆLÒ¯Š<^eçy9ÏFIø¹x“A=âõ¥•¦d(mâ&Gìˆò«2º"mRå‡nò0OÈìÌ%ŸŠ”âKe™VVVõö	Ò‘8\l¶_';g¹œAW¹óp90^¿Î^4rß“;Q>‚ò3f;†í/4ÿƒTè‡’Vö*¹èï[>ÏÔÅ}©¯Rÿm­¾ÿ¿ÃïÿÖ·wê»õFƒê¿Û»uı÷oQÿeÅÌsºı4VÙ‡1W8êò«¼IÙï§ø–nÏÃôøúYAİ•Ï(Á±pËMUé”à”jX4±¨¾RBì›H–¬Ì0EU]ô¢bB-È”¼xİ½9E“h°™ÌÌåã¤ê6•XpäsÉMæVÀËzq-7×òRÜÌ
ôYè:æÿÌß[©2˜$K©ûií(oãqên>ÉAN]ÂûB÷‡«ªe[Á×ºùÿ¨û¿hìÛdÿÛ»õæz´ÿz£¹>ÿyúûÿ*Ô$p&¤‘bH)lÿöÂk`[T¢{ïìfO­ò»”ªT¶e®µH·ÅSÜt3#Å V~óq#egŠ˜DIW™Rœc.œk3ö=¸G¿—47P®ĞÒİĞÃ¤^ìÜ ÜÆB× Ë7aD=ÌÆ)Å½9”6£è2w ¼&ñÓûè&…r×ªa^«6fÕQ3â¨üÑÌ‚Àõ÷T'ªr\øîÀô2³x¶˜Öìly"S+’65×ßFo5ˆY
œP)a¬D÷¨_ƒjº*À«FÄ`ì€ï¿§QÈ]›ó»¶ĞÅySôŠmN~MÚDİ1”¸ß—Ø3râéÂõê	qğƒ¦ÚN³ùÀ 8 ÌM§úêoê¦Z^åiŒrq+ó$nbxY±\ÃI›í}ô&ˆàLú®02ƒ]ÆïKúÌŒ!­¥íO¯]Jé²z{–”Š43¬Îİf–e)®šË*IF–mbäœ€Bz‘Id¦Bw èZ—«ùş‘•ªB¤¯üS’¹ı Gá|ŒfaoÛg±(Š?3ó$Ñ¥ÔˆçŒ„¬h‡aQ¢R 3Ê2æš¢½ü˜Â\‰±‚'9´ÍFÊúêi""ùşûîà”v|bÑìbOZB™WãR™ş£ G÷,7ğSµZ:CNÓG+ÔÈ£.ôLñòg>í‹ÒàèàäíwJ˜ãÔÏ t!9ã­&DÃ†	´\Î½V«µÄ´.ïÚÂ¸&:"ç,ñO„§Š³Ÿ^ä;:–C¿ê‡,â™†óÛç¹|¨¯åœùùƒt«ïKh2¬PIZ˜?ƒÏåûUÈÍ*°òó¿õ…&ÿ!ûşïÿ²è¯¹ÓbïÿÖë÷ŸNş‹[ÿÃ\ı×Ë»[tÿ«¾Ój­åÿÔòONÎ¿l>ø¹ü¯Áó¿”ü›Ííæ:ÿ{êüOâ‡2ÌŠ´	&zâƒÅ{zÿZq¡ô)
Bïe•±‚î½SÄ¢ŒËj»µÚƒãhÃ¦øíE.÷{8ôİè?Xs_ È`®<7S4ê>¦}î\}–tSD9ÆF["¼€‚HÑÂ3NÎjjø¨Ç´4ò14	 ö
	åˆU"Gä”Å	?Î˜36R¥êù®6”åä:N™ÍıG?‰TŒû“ÅmUÇ NÏAˆØ±"?·—‘²şÇ"%=@î"Jñ)‡zƒç¹¸âÉq¥¾åVÍ¹X€‘M?`ÚÇ`@<IòÕøj–j.K‰#R88!“E²rÎc‰`hÓ[ôEöt9?e¸tl‚©àÄõ¬kW,cs‹(]£«Õ*Ù›b"ŠããdòymÖ¯s‰b„/:
…ã[´c–1˜ÀÈ2ò.œú‰¯MÍ<"øÖÂtÂ ½Íß;¸™QAøy^3–M¹çP	7Ğ‚Ğ/ ’7›"´¥­­’ø
Ô+ÑµJ~œ?Ée»¼ñUî;áÜ`
Ê¦÷g0	áŒ+†Î¥	Ë	tò^bü^T:5ß’âÓz%ê±àØ%MZnZDt¢†C‡tºst'ÃŞ¯½£îawƒ>À‹êºWMP?–¿)Ë‰¤f!”A^ƒl‘˜8›}LSŞ,ÚrvÙÙú™•6ñİeï°b"‡:¡Ï ¥H•uşö¥ã¿$w~ÚøŸ‚=ÿÕšü÷?vÖõÿ§iìMğ2´ƒp¯Ş¬ÖšÕ;•1™VH½Ù‘+™ã–I×!»?õ:ı	ûÕ nÿ m;6³kM¬ks©¨®ÜrûU¸ËH¼(ŞÔkÍcªˆP*ù
_}A?tò2i	ğÒU¦QÈã&Š™ŠFHİF]ØŞ®í¨îÒ*O‡ïN=ô¢çrˆ<–şÿØ¿æjúÌTÜ™û5Š Íÿ[µFmw»N¿ÿÕªÕ×ùÿ¿Dş_¡Àîx4›«äßh6BşTşÃqõV£µÎÿŸ<ÿÿ#éÿÍÍÍrÊº”±fG=&]%ˆÏ&ılĞÈùÿ&)ÿCƒØÅd÷ÇAøV`úK «ıÕË
²¯væsçf½nÖÇ¤'×…ßT¤¥ÓÜ5¢¿ìz@.QG”Cş{*ÀÂMÛ2L×åRØ÷–ÕO÷ù+›ì—hæ«úEş1ıÈTÂ“r‘ÈÔl¦ò_ "#ÏÇS‘û£d ƒãßFœ8)î‹|´áBîì.ä˜Ï¸‡´â	ğKÕ²­·Ö0mÒBqcP{(f¿¯ÂƒB¡7ü7&3´šö5NO¿êÈ2BÑÊ¼»tó¶ğå²Õ„¢ó(piÿÿ
Iàgâ¿zc{;ÿ5›ë÷ÿŸ>ÿ<dÆm*Ä}V!C*Ì…MÃcÓ@åöCœ
^Ä2v=*ù™uÒƒê):t¤¢-|º-÷QY˜¦€y?«šå;uŒrƒ|ï•‘ïÉÑ‡}Škj^®Ksõ„d´É èZXúVİœpPÍªw¥
V¡—½£)@Qèn?ïT¨¾ÍÊvìvŠàøOs±·Û&µäº­‡û_¾xIÚ„½¤Ç`èñw¦é.‘¸Øòå“ğïjëô{İÖmİÖmİÖmİÖmİÖmİÖmİÖmİÖmİÖmİÖmİÖmİÖíkµÿ¡‡#B x  