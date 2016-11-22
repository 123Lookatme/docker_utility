#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="3846447296"
MD5="e644d940b4891281b76ad4896f18c4c1"
TMPROOT=${TMPDIR:=/tmp}

label="Newenv package"
script="./init.sh"
scriptargs=""
licensetxt=""
targetdir="/var/lib/newenv"
filesizes="5448"
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
	echo Date of packaging: Tue Nov 22 13:54:19 EET 2016
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
‹ ë14Xí<ı{ÚF“ùÕú+&2-&yÄ§±{NIKmâòÖØÍ›³y©,	ĞIØábßß~3»«O„ã¶‰Û÷NÛæV»³³ó=³+—+Ï¾z«bÛo6é³¶ß¬Æ?ƒö¬Ö¨ÖšÕFu¯^Çşıızí4Ÿ=A[z¾êà§á><îáçÿ¦­\ñ\­òüßßÿ›ûµgÕZµYÛÏùÿtü·Œ[Ãº){³¿„ÿÄlâÿns¯±»‡ú_«7öwŸA5çÿWoÛÏ+×¦U¹V½™´ıfĞïâ¿Aÿä¤3<{éjz·Ş¯c|ò&è›,-Í7mËC¡‘¤¥§N–|AÀ¥	.5{±P-}—ª;õF’tØ?=m÷†’ ê:ğ¦¹†ê44ÛòUÓ2\Ø1-Ğ–®kX>è¦×+Ğ‰ºœû¥2Šb‚£(3cî@&¶‹ÃÄÜÃ%Ú„/14æ†æ{:Aøì‘9…Õ5Õë¹á%a²‰hdQ’%i{pÑƒAÿâ	ä¨®gŒÅ>¡ğ£ôoªÿqn>¹şïÑ³Àşï6¨ÿZu/×ÿ§Öÿ„4ï”à©ê j2˜–Dš„êV’¸R•…¦±‡}úñ ~/‹ÇŞÌœøâû«Wì‹2»ãZÅAÚÌÆYÌzğYÆG“OHùØp1êZ[-ZKL|QÇ5-²9ŸSubcğweÉ|S¯¿­¯cõ"6P‹ÀªI÷’ ”i¡èXš±Sú$¥Èôà>·’›¼T•ÿ½¸»l+ÿ5zQ’¶º½áy»wØijÒß×˜±¥ …µ=m­ohKì†€±D;!’şÉ](fbğİŞáÉÅQ'“GŠÙzÁçxZpŠ•ä¬Šv•ìh‰çÛ/Z÷rÒ'ÅÏ³Ì ßd®NÿíBÒÙ³›L[ÈS §Câáì	İ¦åYñQ¨EŠ†›á_¶o|ºs¿ ñ?÷‡çGİÁ#†Ï‚áí“n{øˆ	j	Úç4apŞªm4%¨ÇèûÎÑ,Áğ—îÙ&`©=8ÒŞ‰f™P©uÛ2ˆŞÌc»†	`	;ŸÃ­éÏ@EÖÚÇÏGOÉÑ£ÁÆn3D"¢ä§é'F(w.(Èm×€•½oé?ÀåªÒŒ#<™kpSÄ¹ô…¬¤v¹z7º4:£Ko8º£%ŸQóİ¥‘èDà„H<™¨s/sl wÆGC[ú1;a¦İ¥Å¡
	kv°+TÓYÊ"ºeø·¶û>=_t?ÆW°¾Üd,”;¾³Dvc`vû¥ØÏ	ÔJwĞ=u¡ZÂe¥AgxqrŞú- õ×ßÖ~“:ƒA€›ˆğQ2Ü1u‡Œ“l¸®íŞ‘ÎMÍ¿[Z6Ş¹Æ‡¥‰"d¸„ç8•A’aß~YÈN ^ğÓÈÁİ$·sdkï1$f(À•XåJN@Ù’Œf%¦/3C#v‰€zŒ<ßãâ¢s€‡ŠqîÄœû†Û’-ua´ˆ1ÊÜûGŠÚ#H|58Ú¯2^9
ÑÎqlµhîõÒœsI+›dµ‡“q©h˜±¢æ^Èùå•÷r‡$¨„_dšÏHª§¤€Â³å|(ÔÙ”˜BdLÀ§ÈvœR§Òø”dÌ	PùŒ¢xËkìƒÂÎÔ@`ß˜÷”˜ªëª«€G^dÚæ6š6d¿ñräULÁø3Ó†•œ&7Ì“^	Ãš9ËK(ˆGĞjAAÀƒÑèø3ÃJXXMt\ã.Ş‡=“}eÆ˜OéZP@sƒû˜~À<±ÅLâJÃˆ
"¾P}(~úäªÖÔ€r÷¬}Z>dyÙıı§Oå!D_K¿¿/2]V36+.S[å0P-Ò=»Ùmë:ª0ş†Œ¥Œ£åNÛİŞxxñS¯scÃÚ×®©O?´Ë;L{}Pô2jWM©—¤Î?»ÃóÎÑ|Ûü2Ü¼êÚTåCé¢ÁMßÿUÈÀŠE;;;`¶ª¯ÌïëÍú+óåK(•^1é#ìYŒhğªåjÁ$óz­‘û(ì¤ô  FÒ[/‘£a¦µ4BC#†Ëe„[©íE†°!M‡K&ao:ªv<ãY2Y`Kêšg¦RŠRùèê€{/‘êq—Ïõî9j†­ÿ]V•ÿ½¼*g˜2J[L·BŸ·eP°•AÓ‘Ù9’B»¤A,"jŠPE’õ?‘Ç=qş_«5kTı·QÃ<ÿâü?³ŠGåµË 'Áeÿì¼Ûïñ…ï#IzŞëŸw€ªbA}Şú§p6èÿ£sx˜±ğ³?xoî:ğ®oÛ½s8ïCûè¨âˆö¡3€`Àíôp1ì`„ŞªL–óùØQ1Ö§¤3Æç’tH–<Z²thO"@og†öÁOP`n^»ª»B0×q,Ë¢øĞHú‡¿toº'¡Ä7÷SMµpim¾ÔYª€ËÜZ´ÕÃ¢$õy†x@)¯w°•yão’D¶†”·Âm.xçÒ¡Š)&7êµ¸væªFÃEƒ„ß]96Fà°CÓBC*1¡öMáÂF*™wˆ.°€ŠñhˆonE/¯G€0Æ#ŠÆ04ã€»S‹Àò€%¢±W^Cá-mØŸ™ğ|:Î‘[Ì àÚÀhHu+&˜é‰³å5ÑÁöLßvWk`{¶‚Üğp0[¤œo<&aà±{¬ƒŠ®³½ÌâÔF5H2K›ª¾3Ûó0-¶K6m->†ÁZÄa‘s2Æà9z(×Û9âÜ<€r¥´¶#¡lazz4ò½ÇvAè2’²•× ‘´o0¥0u¶gÊî/]{éôÎˆa=cİçƒT(z%à¾6á Ğ¡ß’ÔÆ‚ä>P£hÇ<qGºÇ‘¢”B™ü"¥³’$¡å‘¸ÈÕ…ƒòéûwÕïªßUËÙ¢ì‘j®²$§êx¼h“(ëDEFİQAC$wİÓöq§×>í´
Ş¯òX.„FoìihŠ.€¨àôk|Ö>ÿ¹{‚³ãı¢Î…fpÀºTXFÀá%™Âj¸Á8ÁÁññ%)´¯-1+†¬ôÓE÷ähÌ-Š,cùB	·Á pãŞ’…ED°Äs…kDD|B¸"ó®(dOû=VÆ*ß(ÊŒa\‘I+–áP™‘Qà"¶`ö²%³%BÛc“È_eÌàı!wXÁ,0):ßQ4
g™Ó0µ KMŸ§x¾š®Ë|m¿i¥Me‚c4«fMTÍ÷Êår*ß—ŞPKfTŞ@t¦ÿJ•'j¥È¸´“ó cSéA
â_¹—,6"¦A£W"åÃå ë¨È ©r%†R|>pg=&oR™µ‰2ù>Yo\3æúSÒ2ÖÊœ@ÅL–0sB¤§ÉÓ?æû,]‹½´tJTtÓu1Ë³]Ó n_ùñÅãÚÂm"Â&Æ„U`ŸèÁÉ32É">­ñt$	.$§)Ğ!yA¾îYYù*4+W2Á6æºMP»	hA<ppå3˜Áæeœ¸)B(óåX5½‡1d_^Ç¡Äq´Ñ=Æ×aìºZç5ß!’6EÙPÉ8(2,áB¡–áfv.<ŒaŠ/.RÈ¡Í(ë+ñ™”_„³Dğ-Á\´Â¨:	Wğ[Ñ6Ëªarw)nŸŸwzä»à”¥GßŸGãRcáø+Ü/Z$¥²É5n]^YIÙ&ªÁŠüÅ«²”µm¥|`ÓB2hÌ_@)"HŠ&%á„ö'ˆ™¸C-mT€GiX0yMÇ0¶"dK|	T şihÑâşra	2‘yx<“&PÜ±fÃç~/‘şK`h‰B±V—¾Í}0Eƒ<­º¶mŸ/èˆé±;8Ï˜ôÀH§=óP$jë.™ê.¼Ö"m3[ó‡‰Ø*2&¥¾ñ±‡;‰ê7¬Ù øbk'"T~ûó™S+ü€h}@Ÿ1Š9~dÛ¶¨Óqş=HÄCÿâH¦°“:Ø‚Ô$68\»ú'XØœàœ'r‚%æ·C‰|HÒ»rÇ
‹1D×H´ÁÕ_°S$Vc™¤W‡=¼ ËÏ|R–6ÑRñ&!‚rÄ72¸èI	LÉPÄÚÈLÙiÖW%tIÚ¦ÊÏQoÈ"èVkF´Cá;ÂG%(…÷Š2í¬XÑ®Ø7ˆGâÅbbnX]¯_'FJÎ{2ÊGP~Æ|F·¼…ê}2ÿØ¶)-5à ”ò5TKıw¿ÿ\­yêûß{ûMVÿmìÕöktÿ»Öhì×óúïß¢şËŠ™—tQfTa<a®pÒ>æW9£²ßOá-Í`>ÓÃ›JuWV<£ÇD—/ªÒÀ9Õ°haQ}¥„Ø3-X9˜A
ªºhEÅ‚ªŸ(yñºZsŠ&Q12™Ù˜Ë‡IÕ*–XpàsÑ ¦vÀËza-7×òRÜÌôµYhæÿÌŞ›±2˜$K±«L­ oãqìn6ñAİ×úB·MËÓ2ı¯uóûQ÷?ëûû5~ÿ{ÿßİEı¯Õ›ùùÏÓßÿ®B}{L2†“ÈÖo¨/¼¶C•¡¹i½g—@ª¥ß¤X¥²%s©ı]²-¢KNŒƒXùÍÃ†é!ªTp“„«4¯PIAÔ)"åFB	mé¢«÷†'0ó}Ç;¨T¦†_æcÜ·ÔQçgáJADZIu|çBˆ¥¬$ß^¢Ş¢ıHšêÃk¨¾VãÊz°/ì€ï¿§QZ|›­ød-‹;AcÔâxV¥md™®„ıDÃÂ(‰$µ…1û,&*Èr¢»äÍŒ½j"
ÂŸ aÜ˜hô‚í±<
i³Pß—èÅîâ72qCìb&ş^&Gq''­«o%EÍ½áäJİ•e),8Ë¢®,1ÜÄˆJ@²"‚p!VìXƒnšĞåGõ¼[â¸;uã¦b-‘hì¶H”ôü ‘sxÏ†Va/*œ&¡(Š73SÂàê^` ©Ø$¨B=§è(“  ª6#êËé'Lõä`ÿ<) ·HéÒs+á#<ø÷ßwúo¤¸¡;ew&âlI¼JË”x,šk:¾«mÒ™k?Ú¡¦Ct¦-aÒ–>#i]ú'Ggo¸2+Ë¥~¥Ñ™h9B®Ğ­Òv9õšÍæ=²3ƒ®0hCœ9J®Ìüıd9_=Oå
™ x%ãÂK#›­Ğ*£Ô³2	Rú:}í•!µª€ÊO¿Âl¥Lºô7yÿow¯Zİİk²÷ÿªõüı¿§Éÿˆÿ‹•÷a^ùëùİìıŸÚ¦‹9ÿŸ˜ÿÑÉé—Í>ÃÿF}¿‘âÿîn#ÿóÉã‰åÇºê«côÅuäÅ{zÿRq ğ)ˆ¤îå
b½+zı€yKŒ3ªûÕêƒãÈeQ<ò‰<ñı}7üÏæ—ï3&²9S×‰ÍÉuâ>·§ŸEÇda¾şakˆg C3b¸ğğ˜£³>ê1­|Nb»mî8óU€•8Eã˜…¹/gÏ)ŒÀ4"İÕÌ)ÂëEÚ4·eüVä	·'‹UYÃF ®A€XY‡ß[ë@Yÿc’ u¤ø–H½ó\\ñã°b¿R»æTÌ€H„ÓÙœ5¶­1†„ã(Oß©dùÒ:—8 …O'`²¾/Ù}$Qâ-º@Mÿ±H•îñÆ—î 1Ÿ;®yƒì
yÌ£N§²kƒbt¹\&=cKŒE:;Ö¯1Rd$ë‡×©l'€…Áé
õ(]ÄLšCd‘3YıØS'F|‹}saØK¿ÕàW”ogT|š¯êÓ¢XŞµ©„ç«şÒË@¢— °…‚ø
ÔJÁµ:~œ>I¥l¼ñ]ÚË¹Î2d”EWí1ç„;†öµœ	ÊÑìè¦ğ
6‘[Ç^¨àË»*e›!ãØ%=ÚnœEt¢‚Ct¶}rgƒî¯˜!w†Ğï¼(¿ {µ4ëÇâ7E9âÔlÉ¥“Õà
›Å&NfÓÀ˜5¼BÊÒ®»L;³Q'>#»ìu7LeP&´Ä©$=ËÛ—ÿ¢ìñiã
öDüWİİgïÿïí6óøï)»©¿¼^Zşò ¶[®îJT´V‹cR!It³?¨v.^mC—I×á:?uÛ½1û«!ŞQË²-¦×ªæ›7¤+¤ÊŠë¯ÂM¦ â.@q'P¹Q]&Š8«B¶Â«¼ ?röi	ğRL¢aÈã&Š™²FHõ‡h4ª{_sh—çƒwgı.ZÑK9cŠ<’şÿè¿ê¨ÚÌPœ™ó5Š ÿûOõê~ƒŞÿ©7«ùßÿúkøÿŠ ìŒŸÎõ6œÿíîÖÿ©üGçÍz3ÏÿŸ<ÿÿ=éÿííízÊº–±&G=&]¥ŸMúÙ /óÿMRş‡±Å`÷ÄôÇÍğLßğÖ¦lŞôW/+È^¥=ŸÛ·ıàu£&=©.üU™ŠãInêÁ';¦L%êrÀÿô°ÃWÃ2=Ñ5¥\
û~Ğb¥ËÓ}şÊû£ñ+ÚUú1ı=šˆ&Å,–U^°•Š‰?ErÚïE	şm´±íê˜â¾H÷@®äÎñÙáğJéŒ>¤.€?Ê¦e°Õºa‘ŠÛ€ÒC90ûS<(rÃÿÆ\WÃºÁåé¯º±ŒPtƒroúƒİ¼ì}¹l5Âèÿx¸æÿ¿Bø™ø¯Vo4Rñßîî~ÿ=yşç»HŒU,D?«"eæ€B§á±i ²ú¦‚Wa…Œ]È‰~jõ xŠNM‰hŸnaK}UÆB£±É¼ŸUÍÒF¹~ºwª§{RøaŸâª›êR-¢Çm4(¸ˆ¿‡Dwl³²íN+‚Theïh	PºÛÍ;ªo³²{™"8şW|ØÛŸ­ ãZt}öÃí/ß¼$mC[^ÒâpéòwféBŒ¸¨ñå“ğïªyú·¼å-oyË[Şò–·¼å-oyË[Şò–·¼å-oyË[Şò–·¼å-o_ºı/¡t˜× x  