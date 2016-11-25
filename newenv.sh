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
� ;8X�<{�Ʋ���������)i�MNm��9�6�ʒ ���'���wfw�D8n��l�����gvE����[��^�>+{�r�3h�*�re����{F�k�g�x��w=��Où������Xr�����"��Z�R��J�Q)o��t���ú.��?�������[��V����^��7�����teZ�+՝J�o����������k��f@��~���2�'o���oi�i[.
�$��:1��9}��&����\��!\���J�A���=�K�������g�4�l�SM�p`Ǵ@�ǰ<�M���c՟y�"�b��(Sc��<�m�!���K �1_b`���t���#sתc�W3�M�d�ȼ$K�v�����h�:�1��܏��T���|r�ߥg������R����S�B�w
�THu�sLK"MBu+H\��B�G؇���>��_���cwj�=���W�ez˵��0������ೌO&�"&�"��bԵ�Z����� Ǵ�1��lfL�����7�%�M�����Iԋ�@%k��&�I�P���ci�N᳔"ӽ��Jn�BU�=|q{�R�g�� mu���V����U�-��-60cK
+{�Z�Ж�c�vB$���P�� �1:݃���v&�����q��&�K�Y%�2���Ϸ_4��O�-,�g-�A��L��.څ���n2m!O�����$t��d�G�)n�?|�D���Z�q��ƿ��;���[ǝ������hB��YY3hBP����> �Y��ϝ�u�R�4���2�0R�e���v� �6v6�ӛ�����\Y<!G��E���b����u��9�,@n9,m\�1~��e�;G�d��M�b���������h/��� |F�s|#�!��	�x2Vgn��@�O��{1;�a���P��5s;�*��,d�2�����/���/7Y�܎����]�^!�u�BN�tO(pY����5@����_�v����&"|��`LcA�I6�vnIg����������7Q$���2H2��o!�1T~9��� ��vm����}��\�	2[�Ѭ��ejh�.P���\\tp��c�;6g��4eK�Mb���������C�������G�s��E%�{�3.�bes��vq2.2��Q����!��t_�����*�))���l9rU6%��)��Ti�4>� sTE>�(��}�ۙ���B Suu�ȍL��Fӆ�7>�1C���)fZ°����f�y�+�oX3�pq9��M�	x0�ojX	+� ˉ�+�Ň�gl�?�1����rhnp��'���C���0⃂��U�?;�51��9m�X^vw��sq� џ����噮��6+.S[� P�-�9���tU�C�R	��r'�Nw48���>C��f�+��'����-��(z���TR����Y�p�����_u�*���;������e`Ţ��0��W���F����%
�����,F4x	�b9g�y���}�vRz�#s����0���Ј�r�*��!,��C�Gs�%��7��v\�#Y2Y`K�g�B��B�誀{/��q����9j����]�����,f�2J[L�B��eP��As!�-r$�vkH�XD�9��$%�"�{���RiTj��o��[���O��gV�v�C�蝞uz��E��P��w{g�}��XP߃7��	��{�h�f,}����û��~����]�{g=hU�>�����^�m�Л��?��*����b��\��ђGK��q�����>�

��+Gu�h f:�e�C� ��a���v�M�=����cj��.��|��
�̍@[[=�KR�g����q;W�7��&Id�aH�K��w���b�x��P��{��L�h��qb���;˅�8�д�ǐJL��AS8��J����, �|<��F���!`��1�8���"�<`�h�WPxG���<��s�3�20R�J�1fzb�Կ":خ���rl��P�;cnf���-���$<�bO�uP�u��i�ڨIf�3Su��aj��E��v�����0X�8�S�bN���=���rn�C�TXّP�0�	==y��c� tI��+���טR�:�3e�G��/�gȰ�ı���	*�]�p
_�p��wIjaAr��Q�c��#]���QJ�L���Y�?����H\d�O�|����w����ߕ�٢�j�
�$��x�h�(�DEF��QAC$w���Q��:i7s��/�H΅F�o�ih�.����mt�:{ی=���~Q�B3�g]*�#��Ln5�`�������צ�CV��s|8b�E��|���`P�qoʊ�""���5"">!\r�yW2�'��.+c傿(ʌa\�IK���P��Q�"�`��)�%B��c��_e���!wX�,0):�Q4�
g��0� ����U\�FM�e��ߴ�Һ2��	�U�ƪ��b1��Ko��)��}*o :Ӊ�����Bd\ZI������ 񯜋KӠ�+����r�uTd�T�
C!>����N���D�|��׮s��ikeN�b&K�9!������}�����-��t��l�4�ۗ^|񸶰g눰�q !ƁD��'zp�L��O+<J��i
�I^Ђ�zVV�
�ʥL����.�c�NZ�_zf�y'���|9V`MC�b�ė�qh�Dmt��u�.Wy�w��MQ6T�}�K�P�e���sc�|���rhS��
|����,т �gKc0��0�N��V���2�j��]J�[gg�.��}8!d)�����Q������/�%�-�����7��@/��lՅ`E����
��6�R�>�i!4�/ Ȁ�$E��pB��Lܡ�*@��#��4,���c[�%>��?*�4�hq������<<��I(�X�����H��%0�D�X��gsL� O��l��:b:E��O�3&=0�i�<�ڪK����H��V��a"���Ia�o|�a�N��+6(��ʉ��~�|��r? Z�gc�ٶ-�t������8���� 5��.��#6'8牜`�y��P"���ܱ�b��q�����XD&��a/��3��e��Dt�T�I����ϻ�ZS2�62�v����.H�T�9�X��j͈v(|��� ��~@^���K�%��x>��V@W��׉����(o1��-w���L�?�mJK�/�|�R���?��5�R�m������`���ne�R�����ަ��ר��b�]����C��+���UΨ��SxK3�����RFݕ�(�1��Ƌ�t pF5,ZXT_)!vDKVf���.ZQ���%J^�n�֜�ITg�L�6��aR��%�LEt#���^X�MƵ�75=m�#���?��f�&�R�*S3��xD��M|�c����m�bɴL�n~?��g�Q�G�4H�+��������.�B�<{D2���毨/��C���i}`�@ʅ_�X��)s��M�-��KN��X�ͥ�Ƙ��Fhf�Y�ԅ�LP�����p�,��B�+L=L�)�����:�*�T�ʗďt��u���K�q]�0.�����a�yw�T�u�|
nq���:ړ����\-�clCҶ�X̖��u�K���E$�4Ճ�P2<�$������O�0�8e���&3g�����/K�(%���[cJ�:^�^� �c�Tޭ���z���9&K���ſ���O�ލA��÷�@Ѭ�jS����^6��t�I��:M��C	�E�灺������6�����'��rr7�ɝ�VDdD���!K\e�)2v�~�K܋_rE�����}E��j�u&��ql�X�0�eH)'�!uW����/�Hzd��&�@Tb,y��vRD�w�>�Bu�=);(��N�8Q��$#��%Z���q���(��@̮�)i0��r`��
�J¬�!AU.���O�'̚���y�E�>�B�uJ.�#���o��Hq�+vʮ��ْx;+�|��$���n��r1c��j:�Ag�g&m�c��e�w|x���0�OQ�-(m�����p��
m�S��h��#;��ڦs>�ޮ�B��?[>O�_� xq��M�̛��ѡԳ�'	R�P?}7�-BjU�(�=�"3���?��r}����,W7�>��K��������_��Fc����tr�u��/�սZ����&�{��O�2#L��&z�:����, �9����y��];E�r��q�_)x�La��>}?��cD�eLds&�"6'k�]��̞|u��9&�[A<�Å������QAhe�Cp����9X�̑c&:�8c��H1�<�&`^��Ӧ��(�_y�q{2_5�����k ����*P��P�$H])�J�އ�y.�xrX�o�]s*f@$B��l�����Q�4��Բ�n�K�§0Yd
�>�(�&]��XXM��c�Kw�F�|��y��
y�CdT�k�bt�X$=cK�D�a�_aX��]��S�Y /8
��%�H�D�u�؏\ul���8�3��{���~3�����|U��%�M%\O�|7-�^�	��vvr�oP�R�U����I*������g:K��Q�j�9'��1����LX�fG����Р���@��̑�Rj2�]Ҥ��YD'j8�O�[��p������Q{ �.����WM�~���#NM}�(��W�,6q2�8�ƬY�R�v��eڙ�:��e�;bޅ2�M!&H�٦}��/Ju�6��`O�������zc�=Ecoj�W�����z�\����pȤB��͎T]&]�l��iuG�Wc��æe[L�U�3���J�����p�)�8sP�1��U��"�*��pK/�cN�C"-^7J�1y�D1S�����ޠ�Zy��i��Y��i��V�BΘ"��?��.Tmj(���1� ���jy�V��j�+���O��#��z}���zU��8�Ҩ66������%����YMYW2�䨇��4�I?�r��H�� ��잠�����ʔ��~����Z��}�^7�bғ��o��8K�֨|�3�T�� ���7���i艮	�R����K���W6ُ�D�/i����{DM�Y,+�`+�� 	~>��ߊ8�m�����H�@.������R�>�.�_��e�ժa�����C90�)
��1��հ�qy�U?��nP�M�ߦ���ï��F��W��#$�_��*�Z-���{�����?�Ab,c	 �Y�)3:M���0�+d��T�5P��St*h:HD�t[�Oen������Y�,ݩa��{'z�'��)CuR]�B��qOF
.����EŬh;�� Z�[Z����N��۬l�^`����{���a\��Z�~��囗�mh��Kz� �g�n�[%_?	���I�7m�6m�6m�6m�6m�6m�6m�6m�6m�6m�6m�6m�6m���/ǟq8 x  