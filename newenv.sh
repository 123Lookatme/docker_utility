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
� 9YX�<m{�Ʋ�j���L�I!�`�:%-��é�`7'צTF�	HDv|b��~gvW��mc��\�O�vgg�}fW.��������購[+�?����]��T�����3�]{�gO��o� ���������h+�;ԟ�����v�˥Zyg����ͮ�}U�&	�kh���l� �Kk�?z�|�_Z�~ixe�M��>�������fW�;d�k7�5ۿ�ɛ�o������
��,<c���}쁐&8:��a�}87ܱ�W����q�}��S �4A�����4:�oX6sa˲a�p]f�`Z.\ހ�F�b���c�r��i6�CF������%�H,�cS6�?!|��Õ�Z��yI�|��G��󽍍��!���	S���L���I�OQe�{ֆn���97\�$U �����87�\�wK�
�y�R���n���X����B>�
�T�����
���&���TE���C��a�ܫܩ�7�F������Mn�V	l8qp�b�d�)8a��94|�t�nv�-�!a�Ί�!^Ե�X����� sײ���t���$����V��_[YF:�Eġ�e�1T�IS�F)��l��YIQ�^�l��hG��_ܞ7���((�v���o�see#N��-(,�icyCr7�o$�	��O�B���si������<Ҭ�1�C+�Y�ד���E���'�o��ߩI�[X>�Z0�~��1�C�I�̹��EN�"g�H8�����P�!n��|YG���J�q��ƿ��NZ���G�F��4�NiB��^^1hLP��< �U��ϭ�U�R�{أ��2�pR��͈�ܹ�3�6`	;�
�l k����G�)&@ێ�2��DDc��'((w.hsP.�g��e?����#�92�IkŹ􅬤v~�Κ�s�׿��Q��KtH"B$�����96�;��~̤gXtwa�R��-�
���t��n3��q?�����x�+LV�B5����n��.a��9�r!'���.�
���m�ΎN������oJ���tq�1J�[`c���8��u���pj�ۅM��>.,	$�9<ǩ�
}��[�Bv����Fno!� ��g��g��\�U.��/�iV��2aCb�\�=�S �{������ܺj3V'�hq�(�� �98�	�_m8\?��q|�h��
I�+[3d���q�h������^����r�$��_T��H�������0��)1�Ș�O��8�B;��)Ș�*SM�����1C`�@����7��ȴM4m�~��r�UL��3˖����A3L�^IÛ5��s��GP�CN~��f'�,%:.q�ſrc,���pmȡ��}��0On1����9el��a ����5�1�b�q\��)������D_�m��幮�Ys>+.S[e?���"���j�4Q��7d,�`-w�h������S�+־t-s���.o1C�A3��]e�RP��l�N�\�]��so��KPi���?��0}W��5���v�����^Y�Wj�W�˗P(��2�Gڳ��%����E��rH�#��҃��Ko�@6��Y����FW�W/�D��!���L�ޚS�����G�d�Ė�5-�(L���o0�� �@�'\�л�s��~=/i��yQ���qeT6�:n�>o�Q��Ak��-
$�v+H�XD�9���<[������㟸�S.�j��S+UD�g����<u�'��K����Ї���i����7������9m��9��.��v����Gs�0��g��޽mv��s��S8�@�� ��F�م`� ��t��Ĵ�����`n`G�f�sE٧�d��E��M�k�O�`j]��{�V}j�X�FA)Du�7��fO�{���аq��ta�����h+��yE鈴��F<j�<Ċ�&I���Hy7�͙�\̩b��W�M6��j>5�4\&�1Hƹ7s�*آi!�!�mR{��m� �,[�~Dx��x�+6ל���}���Lm�1��[c���(4��W\B�m؟X�"I�#ט�%��p+F�����%���,�qo����59�)%�7 � ��:��&��$NmT�$���ex�;� �"a;���Pc8�Y�	I� c�|�a��mn�AQ/,�H*[���znJ�b� t9I��K�(�q�0O�L�g*ٜ��b�F8}��8�uGNP!�a�S�ڄ�D�~+J�B��@}H���jҕ8�l��1*�\!R&?��/�<�Y�ɘ�Q>�9|W����]��-��� +j�8+*q�Z]T9);U�d��:n6ۍ�f=�l���\hd0��=M�9�e9	�~N�o�'8;�/��h��+@���$Qg�m��3�	N�/(�}��Y1d���ZG=S�K�J�E���i<�尀� �kB#"2��%�wM#�x�9k��d.�F�Cc]�$�#,�¡*'��En?��e]�K��/�'��ʘ!�C��*h&`Rt��h� TC3�a�H&6�>O�|5�T1��|��?�)�j?�h&/Q������TGyC�u��Q�
�	X�����P���T.Dƥ�4�{1��IJ�Ԩ��d�1꿒U1\��*G�:�Ca(��<"o�R���*�>�.�\3��S�2�ʜ@j^�HOS�����ga��}���b��#n_������"�*Ɓ������3r�">-�H.$�i�$yA��YyM24+*�fS	]
�*��� ػ�9�`�*N\!�r�j����2��(��r�8����pv],�Z�I��l�d{�p�P�p3[g�0���)�N(�/��3�_��Dp�-����è:	W�[3�7��arw)�n��6�������ND�_F�R6��7�_�HK/d�ˮ]�^�I�&�K���ū��U8<J�����<�и��� R:D�MJ�	�O3	�ZX� m1�&Ұ`�q`|EȖ�8�4�@��Т���*�d"�� x&M��c͆/"�v"����	�bm,|G�`�EZu�8�X���p�{J聑N{�LԖ]2�DM��2��UdL
+}�CO��G�d��-sQM�w��N-���}F?���m���*���>�7�s��V�R���p�ҟ<7�s�û�	��%�>IoQ���]"�
WƏy�Ef�^Q���*�8�KY6�HDwHś�ʑ�H����$0%Ck#3��G��J育I����-!?@@��|
2P
/}�U�Y^^�o���b��:��|TX�N�KMS����E��2'�'��b�c����>*�f��q(ie�WHy��o�<Q������[[}�G��-o�w˕
��w+���ߢ�ˋ��t������1W8j���Q���n0_�������+/�Q�c�ˍU���jX����RB�1D�^搂�.ZQ���'J^�n�֜�ITX�L&��aRuK,��F S;e�����kE)nb��I����s{o��`����Ճ�MDı���5v	�+�.�m��u��A��wK�����Nm��\�������N
5��D JL"뿡���U���;��S*���*�uUH��m��nb���o:R^p��I�t��9l�\�������s_���.&��s�v>X�M�|�F��u�R̅;���f�\FD��qzܤЮ��Z7ٕncV]�5#������ޞ��BE17>�[�&Z�I�Z�kr�4��)��|>�	�j���;4@���
ݣ~:󇺜^4c|�=�B�ڂ���dM�;B�X藔M�S�=��1!#/\�^�0h*�T��
��]�'�u��?����ѿp�v�(��	y�Q��Ӎ]a�,�Nk���Evh��9��yaC&�����D�^M���dO��_�����x��6�`7��CQ�)�P�,�� U6gƇ�����gd,�����t�+v\��ߕ+8&ui�Ģ�ؤnf��� �:I��p�����u2+���՞�s����y�fR�P��w��,�5He��l�
s�8	EӼ	C�*l��i$��q � %]�u!A`!���O�'�,�)D�F!C����=BMFW���Q�F\n�_R�s(�_,��L�qu�bug:��G;���i��ϯ�����ɻa��E�RoAkBt^]���yh��z�Zm�J���q�<{�I�|"��|��ɵ?��#�o����bz�<��eu�3/})���>U�]I
��	���"�V�P�Y��.����-��-WwJ��N���[����}����?��>N�����]��_�����'�tr�u��/���������:�{��O�2̊�&z���z�Z�C�s�ݩ:REL <2�2��R��q��(��L��n�������w���;���u�>u�_D�da���=Ö�@�f�pѸ@g56b�CZ���$�
	�V2G��)�8Θr2R���M�����q�ia?��M�1�n�� A����ח����%9@�"H�-�z繼�)`�~�v-���M���`9����j��-sI ��t�� ��?0�
��P��"�?��������O��k]!�B�8UF��ڨ],I��Y\��[�Ė���Tr��B���X��"��ɺ��1bi@�-��s~}[�wp=�����|ÜY6��C%\��^Z����mm��wР\�U����I*CM�r�YLM�!�lzwA�ch\:���͎�Kߋ����[Rb�Cנ�6d��Iۍ��N�ph�.P7�������f:m��t��f���&�F��,8�L�Ba��$���`�f�WHY�ec�igV��d��Ê���p1A*�_H���_�o>m�O����JU��?v�����4����ra���r�X�*T#^��R�(�fG�d�.��C6j5��W��탺��\���o]����v#�W&Sqg��#Я��"���Vx���A'�!���(�$�8�"n��)k����I�ׄ��Ҏ�������N�蹚1E�+��ߘ�	���c���J���v���W�T^��	����xT���_�V+��T��q�Z�����<��=�����rʺ��&G=$]�_L�������MR�����{���fx�ϼ�)�7��e��өs�	^7kcғ��_�X��
kT	>c��q�]��T��3�bf�kL����y�%�}��&�K4���E�1����&�,��/�J�?�D���"9�����6��qMLq_�{�j��d�w��tFR�E˶�F��$���>��P����
�܈�1����W�<�UG��n��M�ۤ��탯��F��G�K����/����v*��V���?}��H��X�~V#E���N�C�@��c�
^�2~=*��uԃ�);54$�5|��-�U����a�ɢ�W�ҝC�r�t��L����>m�7�ė=��h�A�����0�m࠘w�KR����%@��n��Ԩ���v�v��ğ��o��8�k�	ڏ��b�	3xIO��+ޙ��7�2��O¿+���u[�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[��j��	]� x  