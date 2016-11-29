#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="1709597369"
MD5="6694d1018991a73482606eccdf6deb86"
TMPROOT=${TMPDIR:=/tmp}

label="Newenv pachage"
script="./init.sh"
scriptargs=""
licensetxt=""
targetdir="/var/lib/newenv"
filesizes="5609"
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
	echo Date of packaging: Tue Nov 29 11:18:24 EET 2016
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
‹ àG=Xí<ı{ÚF“ùÕú+&2Æy„ø´{NIKmâğÖØÍ›³)•A€€D$aÇûşö›Ù}!§İöíÓ «İÙÙùÙ•óú³Gol»»Uú,îVÑOÙËØWª”wvwÑèJåTŸ=A[x¾áà§éŞ?îşçÿĞ–×=w ?ÿw¿Èÿj¡\,V°¿X¨kş?ÿmóÚ´¯òŞä/áµ¸Ëø_©î”+;%ä©¼‹ú_XóÿÑÛæsıÒ²õKÃ›(›o:íÖé>şßi5:Šç,Ü	™Vã]£õkŸ¼‘}£…=ğ-ÇöPheác³¦ÑÇpi‚ó3›ö°ç†;özŠ²ß>>®·º{Š`‡ÀÛÀ5ß¤i0plß°lÓ…-Ë†ÁÂuMÛ‡¡åÂåÍ‘±˜ú¹<tM²b‚£is:‡,Œ‡!ˆ©‡K ´_¢kNÍìéá³GÖ®×2.§¦‡É&
 YEU”ÍÎY:í³S$ĞÜp=³/ö	™Ÿ”¨şG¹ùäú¿CÏ„ı/TªeÔÿr±°³Öÿ§Öÿ˜4oåà3©á™ fŠ*X¶Bš„ê–S¸Rå…¦÷±‡}şi¯t§ŠÇŞÄùâû«Wì‹6¹åZÅA˜ƒ‰ƒ³˜õà³ÌOŸ"&"ò±ÁbÔµ´Z¸–˜¸ƒ¹kÙşTk:5ÇÆÄÆöà;ïÂVù¦^¿(-cö"6PÁš1PîA(ËFÑ±æVî³’ Ó½ûÜˆoòÜĞş»·}{^×ş«·S6š­îi½µß¨eŠÊß×˜²%‰ÂÒ6–7´!vCÀØFÂIÿä.4+6HxŒfkÿèì ‘Ê#Íªmó9‰Ü‚¬Ÿ¥.âµ,ñ|s»v§Æ}Rdañ<mÁú¦ÆøÑ. 3gv“iy
ôtH<œıá0thyAV|h‘6ÀÍƒğ‡/kˆ7>]‰9ŸÑø·íîéA³ó€á9¼~Ô¬w0ÁÈAıì”&tNkÅƒÆõ}ßÉ Z9èşÒ<Y!Õ;‡]Ú;Ñ,
#õĞ±M¢7óØî„aØDÂN§pmù0µÎlîƒç#‹ÇäèÑ`c·ˆBÑLòÓô£”;´9¨u×„gŞÂ5„ó½ÕGxsd®ÉMç¢ìXIíüæ}ïÜlôÎ½nï–~ä xFÍwf¬C"öddL½Ô±RîÌOæ`áGìtŠ™v6‡*$¬–ÙÂ® P‘¦3—FtÛô¯÷Cr¾è~ŒG°¾ÜdIª™-¾@vc`v	»¹ÈÏs·ì»PÈá²J§Ñ=;:­ı.@éõ‹âïJ£Óiwp“>J…[0Ç®9'ã¤š®ë¸·$„Skàß.l
o]óãÂB‘@2œÃsœÊ ©Ğƒ/ Ù”r~9¸½‰A|;Îà†Ä…=¸«\¨1*[’Ñ,Çôebˆ]" îã#Ï÷¸¸9À¹‡ŠqîÈšú¦[SmcfÖˆ1ÚGÜû'ŠÚCH|59Ú¯6®hç¸¶‹b8÷raM¹¤Š•­²ÚÃÉ¸T8LÈXGÑS/`‡úòÂ{¹E”Ã/*ÍgÄU‚SR@aÏÙr>dJlJD!R&àSd;N)Ñi|BRæHTE>£iŞâû ³56‘Ø×ç=9	Óp]ãFòÈMÛÔAÓ†ì7? 1C¼Š(fÙÂ°’ÓÁäf†yÒ+áoX³Fp~ñj5ÈxĞë½bÚ1+ƒ ±KÜÅ‡ gd±¯Ìsãé/\2hnpcÓ—Ì[Lå!îqNiñACÄg†ÙÏŸ]Ã›oÔóû,/»»ûü9ße€è«iïî²LWåjÖœÍŠÊÔÃVÙ—
á±Eš'W•úpˆ*Œ¿!e©ãh¹ãz³ÕïıÜjœ¢ÅX±ö¥kÇæÚå-¦½>hÃ<jWQ+å”Æ¿›İÓÆA|×îüÒ]½êÒTícî¢ÁMßdË¤`Å¢­-°j…WÖ¥jé•õò%är¯˜ôö,B4x	…|!c‘y½ûÈl%ô #Ff’[Ï‘£a–½0C#†«y„«wBCX‚‡€ÖœK&aoÍ)TËlyæG²dªÀ–Ô5)Î(L¹Ê¹üwĞ• ÷#Õã.ŸëİsÔŒ9Ôş~;/hÿÑ{y‘OÿÌ0eT6˜:n>oÃ¤ `#…2Ö\e[äH
- ìV±©!YREQbõ?‘Ç=qş_,V‹åDı·\Ü)­óÿ§ÎÿS«xT^;—9iÎÛ'§Ív«‹ß(|ï)ÊóVû´±T“õ=xÓiÃI§ı¯Æş)`ÆÒÁÏvç=¼{Ûè4à}ûŞÕ[§pÚ†úÁPÅíC£révÚ8ë60B¯é£ÅtÚŸëSÒ‹ãsEÙ'GK-^:tF! wC{ù4˜Z—®áŞ ˜q,ËÂøĞHfÚû¿4:ošG®Â7÷SƒaãÒƒébÈR\æÚ–ĞVV³ŠÒæâ¥¼FÔÁÎæC¼IÙvRŞnsÆ;sª˜bÒxeLQ»{àùÔĞp‘ãD ¡ÇwoæFà°EÓC"1¡öMáÌA*Y6wˆ.°€²Ñhˆo®EÏ¯{€0Æ#Ú€ahE7Ç6åKHc/¿„Â;Ú°?±<àùt”#×˜AÀ¥‰Ñá"VCa¦'L—DÇ³|Ç½YÛr|äæˆ‡›€Ù"å|7ÀCaK±§rTô!ÛË$JmTƒ8³Œ©exà;0q<Ó<pa;gÓzPãc¬YÖ	I1'cŞ|Êõ¶87÷ ¯ç–v$”-bOF¢÷È.]FR¶ò$r€Î¦Öí™²ûóC×YÌ[§Ç°G±nóÁ1*d=Œp
_›pèĞoE©cAr/Õ‡Ä(Ü1OÜ‘®Äqdƒ(¥P&…HYÉ?”¿Àò(\dÍOÆlòéû÷…ï{ßòé¢ì‘j.²¢&êx¼h+ë„EFİQAC$wÍãúa£U?nÔ2Ö¯j_ÍFoäi`ŠÎ€¨àô«R?}[‹<ÁÙÑ~QçB3Øa]V†pxI&³…n2Npp||N	ìkMÌŠ «ü|Ö<:è³@‹"ËH¾†P‚m0(Ü¸×TMcƒìñ\ã’Ÿ.™Ğ¼k™ÇãöY‹•±2òE™Œu•‘T±Ü†ªŒŒ±}‰ÙËšÊ–l_0M"•2ƒ÷Üa³TÀ¤è|Gá8XÎR§ajA&6š>Oó|5}¨bğµù¦¾ÚUV•	ÑL˜¬š52¾—Ïçù¾ò†úk*ûØ£ò¢#Y˜Lü#|ÈİW(æBãRÌ½ŒU¥EÆ¿j&*YlDDƒz¯DÊ‡«ë°È ‰²C.:¸³î“·N¨ÌÒD•|‹¬W®qı‰i)k¥N b&K˜9!’ÓÔûéñ}¶ƒ®ÅYØCJT†–ëb–ç¸–IÜ¾ğ£‹Gµ…=[E„UŒ1–•aŸèÁÉ32É">-ñ´§.Ä§iĞ yA¾ìYYù*0+*Á6§ºUP›1h2Ø»ğL¹y'®Šò|9V`MBoaÇ—×qh±DmtÑu».–yÍwˆ¤MP6P²=ŠK°P e¸™­3c˜¬ôÅY
9Êúr|æåÃá,Ñ‚ ÜgK#0gµ ªÃüÖ†÷›eÔ0¾»„@×OO-òİ{pLÈRÇ£ï/£Šñ)9›û7¸_´HK/`“k^»½°ã²MT‚ú‹W+dK–µ¥ìI>°i4æ/ H$C‡¢Iq8ı‘1w¨¹•
ĞâãH`B““—tŒc+BºÄÇÀ‘ğ'AIñOB7õ—«KYˆÌÃƒ4à˜$¢5>ğ[±ôO.¡%ÅÚXø÷Áò´êÒq|¾ #¦SÄfç88cĞ¥‘Nzæ®HÔ–]2Õ]x­EÙd¶2âc±UhLr+}ãC;¶bÕoX²AÑÅ–ND¨üöó™SËüˆh}DŸÑ‹8~dÛ¦¨Óqş=¿OÄÿâH&³•8Ø‚Ä$68X»ğ'XØyÎ:Áó‚›DŞ'éM
¹#…Å¢K$ZáêÏØ)«±ˆLÒË‹Ã^åg>	ËF	é‰x“A9âéœµ”•¦d(dmh&»ì4ëQ	S6©òsĞê²z‹Õší@øğQNJÁı€¬J;Ëêƒö¢‘x6›T@—Âë×±‘Êüího1ŸÚŞÌğ>*©Šè8”–š°—Køª¥şÓïÊ«5Rÿ­®¾ÿ½³[eõßòNq·X¢ûŸåòîºşû÷¨ÿ²bæ9]”ééìƒÇ¡=Ìê‡ü*gXöû9¸¥)çó0=¸©”RweÅ3Jp,t¹Ñ¢*ˆ œR‹ÕWJˆ=Ñ+3H²ª‹VT,hø±’¯›¡5§hÕ#“‰ƒ¹|TİD|j º!ÀÄxY/¨åÆãZ^Š›Xş`†#ƒæÿÌŞ[‘2˜¢*‘«L5™·ñˆ8r7›ø Fîk}£Û¦yİ²-ÿ±n~?èşgy·°¾ÿQİAı/–Ğ\¬õÿ©ïë¤P}ßé“LHÁP"Yûõ…×À¶¨24µììH!÷»©TÖT.µ_%Ûâ)ºäØH1ˆ•ß<t³¬àL“(éj#ŠsÌ™se¶=øÅ˜ûÚ5}¾p1©~´›àÁb>¤{aÈ¦ã”b.Ü)T6e¼·Â¯‡)ü WºkWPz­Í+İÆ¬:'jF”×=‚‰ïÏ½=]Ç…ò|
n|·à-†he&Áj®ñÕ’HFv¤lóùôFŞj²â;4@™°ÊÀğá5è¦?ĞÅôüP;à‡hR×æô®E'[hâÜZÅG¿ l¢ìµ ßSØ2âÑÂõêqğCªÂN¥rÏ   <0½k±»†Q`ôg}Àxâ_›ô/¼İ?ŠqÆ`BƒBBÔà+ƒéúˆn;	P§50³ £Ñyv8Ÿ6bñó"Ä†L¡Á>³±R½ß3Ø±Éş>¬më›ô¡gùx‘“6º`7ñ“AQ¼©‰¡rQD­2ZU6gÆùVƒàrôŠ,2–İ”ÅßKºÉ;ªq1MîJ‰ã:Š´S"1uLl—xUU	N T¤LUnbDMÆ:‘	íbjOWè6ÓÜğ¼ëa\ÆP¬¥îñë;aú£*S™àâ­ÂŞ9CÑ4ob"få]LIs>V3%b1QÒ•"ÿZbæRo¼ü”|ÂÌ¢*IÁ6
¤â.<W÷5]ığC£ıF‰q±ivŸ%Ê¡Øk^‘,–ç92XcêäEêÎtÅv8Btªg‚—<¿ª]dÚG'ï¸ÙÓ	J½­áyu>D.0ä¡írêU«Õ%z(RQåqŸ8{aI¤x"¬¦x”ç5¥pèˆ}„·`ÑÛh1½yÈüRğºÔ™—¼`Õ‹*ÃŠ®$…ÉûÉk	^«
¨ü,óOäyföşïVv
…ÊN•½ÿY(­ßÿ|šüŸø?»ñ>Nõ¿ÿØÍŞÿ*îPü¿æÿÓò?<9ÿ¶ùà—ò¿Òn9ÁÿJ¥¼~ÿ÷Éó?…Êô1+2ú˜è‰ëè³ôş­6‡Ìg¸İ©:RyLÀ=2Æ2…İBáŞqää(æùLŞşn‡¾ïşçóıw)Ùœ±;ÌIuà>uÆ_DÇ¤añÄ=Ã–OA†fDpáÑ8Gg56|ÔCZùœÄ$ö¶åˆ+‘#rÌ‚”†gL)ğÀì&ÙULu‚ë8YÚ4·yü&ònOf7ùÌ{"k v¬Àƒïµe ¬ÿ¡@IºR|K ¤Ş‡Ày.®xrX‘_‰]s*¦@$BOélÖî;vƒÈ~˜ïÔ²ôl™KÆ§0UøçìÁ°§P¾5º@Oÿ±h˜îqG—î€õ1}êÏ]ë
Ùğ˜Ç©"²e×FÅè|>OzÆ–è‹âBx‰±%KlY?¼N$W<
…ãÔc‘bˆ,:'ëÂ±ï{ÆÈL‚8Ğ·f¦³ğke~EızBáç‰ùÆpfÙ”/¸•p}Ã_x)hAøŒ›ÙÚÊˆï A1'¯UòãüàI"CäïrßYL‡,+BFÙôªîœ0bÇP¿tä™°Î_a^¡‰¦“Á5|™C× ä6`»¤IÛ²ˆNÔph‡.P×à¤ÓüòÃFÚ-€íü6İ«¦Y?e¿Ëª!§&Æ¨!Y®°ilâdöp0ŒX3é–vÙØ¥Ú™•:ñÙe¯;bòƒ21˜@DrÊ³uû¶ñ_˜o>müOÁˆÿ
•]ö÷v*ëúÿ“4ö¦Æâraû‹½b%_¨(T#VúcR¡(ôfG¢d.“®C6~nÖ[}öWc­ƒšíØL¯o]™KEuí†ë¯ÆM¦ âÎ@sG _.Eœ¥“­ğômúƒ1'ï!–– /÷Äú†<n¢˜)m„Òø÷I»Û€r¹°£ûƒ9íò´óş¤İD+z®¦LQ{Êÿı7æÆ`bjóÉü1Š ÿû_¥Ân¹Hÿ©Z(®óÿ¿„ÿP`w<*•Uü/U*%Á*ÿá¸bµT]çÿOÿMú}}½œ².e¬ñQIWiÆ“~6èäü“”ÿ¾AìC3Ù=ÁáÃfx–ozKSVoúÑË
ª§×§Sçº-_7kaÒ“èÂ_úXœšrkT’Ÿ‘ÓÓ(ÈÿÓÀÂMÛ2‡±®1åRØ÷@³z“§ûü•MöGKBâëƒ‹äcú{D!M²i,Ó·ÙJÙ?DŒŸÇ">íkÑ@¯ï¸CLq·“=Pƒµqx²ß½P:£©à¼e[¶Q2m’BqcPz(fŠƒ…BnøßŒájÚW¸<ıU?–ŠnĞàM»Ó ›·­ƒo—­†ı—üÿ#$_ˆÿŠ¥r9ÿU*»ëüïÉó?ßEbÜD@ô³)Rj(tšj7ƒTğ"¨±ëQáO©ÖaŠ§èÔĞtˆVñé¶ÄWmfÎè¶™ÌûYÕ,Ù9À(×Oö‡É~Ø§ÍMÃMtóAH{2Úp¼½F·³¼ãuA*´²·´hİíçÕ·YÙ½ÀNÿ+Nìíßš„Ã¸^‘ ıpûË7¯(›PÊ—ô¸\¸üiº#.ƒ|û$üûÂ:ı^·u[·u[·u[·u[·u[·u[·u[·u[·u[·u[·u[·u[·u{Œö¿¡
  x  