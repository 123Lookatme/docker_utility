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
� �4X�<�{�F��5�+NdZ �����:!-��ˮ�`7��Y*K�$Ev���o��̌�Ȏ�&n�[M�͜9�9��R}��[[�٤�z�Y��I}�Vob�����V���O��=_u��p�w����V�z�V}��Z�c�I�^k���O��qeX�o�ȿYo1��4w�wv(��vk�	�r����zaZ��[H[o����>�?u��g�]̀B�����u�O�}�����my�4���Թі��c�6�X�W+��'0Vݹ7�����q�0ړ$ Uׁ7�5Tߠi�ٖ����Bɴ@[��a���.\\�n����/W`dP�EYK�0�]� �.��f|���44���g��9\���^,/	�M@c ��,I[ó>g�� Gu=c*��O����K����nk[��Vkw�E�������B�Ke�D[H��uLK���ۭ,�MU;}�}�88��O{�[Y<����_�d_���U��-l�Ŭ�e|4�1�6".F]�Ek����ฦ��@6�Kc�.A��y�̉z�}c����z��TM���LU�ҌR���bӽt>M9V�M�ߌ;��M����������u�)��)�AR��MO7	z*�!`���b��B1����������2R��s>�3Ђ�P�&gU��dG�H2�z޾��>)��x��`�fKu��x��v��d��<z:d���p�mZ^���Hѐx��E�Ƨwb��W4������7|��E0�s��0A-C��&O��;�	�!����Cđ���h#�d�b��m� ~2��@�-d�r	W�� Eg�<E8'G��EL��b���U�^��8 w\��5xk������d�9(<��.��/�������N��hrC?�>��k#�!���x2S�^��@������cv8��k�C�.��+D�X�b�e�W��>=_t?�7���$"�%�Y��1�V9�s�rA�t�]��qYi����@����ߤ�p8"�>J�0���׵�R¥��7k������6Q%�cx�S$&������e?���@�A��[{�!/Ca��*�r�̖d<+���04������=�.:�x��1���K�p۲���6	F�����<����P�� z����A��(G2�h���\rM+�+���q�h�б���^(�Ź��DT�/2�g$�礀��|(4ؔ؆Ș�OQ�8�A���Ș�*�E������@	`ߔ�����ׁ��ȴ-m4m(~�=3������LKXar*���0z)�	k��c(�G�nCA����%��JXXKt\ �Þ�ɾ2c̍��v-(��A:�O��)C�ѡ4�� �+Շ�O�j���N:Ǖ}�w��~�T1@�հ���"۫�j��f�u�a���c��N.w:��[C�R	��rǝ^::���=E�q����ύ�E���>(zwW]i���?z����|;�}t��p�(ʿn�.���BV,�)��l�^����K��(�_2�#�Y�i�j�Z�$�z���(�R�� FҤ����0�Z����
­�w#CX��P���5��7
�
%��@�L��vM�3*S9Ń�r�;����i�q����3����ה���8�d�f�����4�yO
�fp�tdF"GR���� 7��pE���'�G���V��k��m�������c���U<*����t���io��7
�'���?8��Uł����d8�[w�0c��`����v����v��p:���P��Gw�:�[�l���]���˩�b.@I/f��$i�1y�d�ОE��.�����ҼpU��RǱ,���@#Z8���;|�;�$N�;L4�¥��Zg�.se��%i�3�=Jyո^��[Gx�&2rR�5���k�*��4^�K���=��T5.r�$��k��J4-�1�jo�T�l�iq7��ؠ��8Ap�8:�� F��(�p�U'I��4U|���\@c6mm>��Z�a�����1x��V��J�{P��7�
��D�I1���3JB�_���7 �S�/1L7u�埘�]{��΄a=�c=��\(z�yq
_�p��oI�`PN���>��'��W�]�(;�D�tV&�d�V�������rL���P���V��G�)|INվx�#Q
�
s���a��9�����T.��r��D5C$S�kz�9��{�n.�/j>h��KI+I8�<Q(����_�B[���X�|�;:������Xn�PBjn�ڲ������d�pM/DvGa�"S�(d*�g}V�)�("�a\���{�P��Q�"�0{і��ǱId�3f��P:�x�	�60�(�E��i��9���Ā\�|w�.c�����:��J�q���3S5߫T*��XzC�m�}�Q) �	D�N�cr(ߗ��ˑ��,�TP�b/�4]�X�)h\��1/Ev�cI9@3��!U@���G��p>pO5%W��#e2�,�s͘�K-H4e��9�*},�䤧���3<�-}���t��u�u1�]� �����ۃ=��	wI
$�8P���Q����%!��4�� h�Y$�\��vB;r.l.� }�h� x�A�;���8�x��k����&���Hk��P��8(���B����P:�04,^�H�\[P�R�3W(0_W�}�,s�c�$\! E��0F�*I]J�:���>y�=8&dQR"�<��V+ǿFz�&,�PL�q���J*q]�Qd�_ޡBA�f�/��ʐAc[ �H�S� (���� �.�|����8R�H��Jπ�![��H�Ӡ�OC��{��K�Y��t�L�Aqז�o����D2,�A2�Z]�6��g� �¶}��+�3���8<�����#�6l:E��ʀ�ŌW��MdK�1�Z�/%���at��7
�T���̭~D�>�՞�|-�4u��zN'�R�R���p�����9��C�~���P��S�E��zW����d���K�E2�U��򣈔	#B"~C*�#Dz'2'dx֗�d0��H#{8b�,ߔ�ei�
�VK��h�Jw���"D	���2QV�j��ă�b117,�m�ׯ#%�=Y�#(�`�[�J�>H�;�ж)�3`��r*)�=��'�V<����V����w�z���mo�y��/Q�cŬ1]��T���&.u�U>�%�����{��j��JFݍ�(�7��ŋjT08�z-,�o�z��+2HAU͙XP��^B�J��+�6�a^qz� �REt#�)
x�*��%#I^VZ���� MÜ�^3Vґd)v���.<���%9ȱ�:_�a�jZ���n�>��_�ժ��������z����{���U�PSߞ�N�!�4���^�)Q5diZ��%�Z�7)V�k�\k�H��S􍉑b+9y[�}�[*�i��4��HA�'B�R|��v��z�#X����U�sï�1��
n�[���J�kN��:��s!DG�R�%�^�/D�H���k��V�*z@v��W4
�1��َO6Ѳ�34Fm�gM�B��J��I4,WHS����b�j*'q �K��� �.� 	zƥ�F/ �e.ț��>�D-����C���<���
L��N(N[)V�I��{)K%ؕ�3(�RXd���]Yb�	�K@�"�a�V�DO7�r��zޕq�H��qY���4v� �>~��6��A�����I(��-��6ap5��0�Sl\��Dt�IPCHpU[�������~��[
�t�U���ի���7�Rv�K�U�t&)�暎���{t�Ǐ(�tH�δ%L��������������:ũ_@�Bt&V���st�D.�^����Gv��f m��D����������RA{& ^;8��ǈf;�ʨ��0F��>�LdzH�*��0m��^������[���6��_����Gz��俺�>,�����I�?께.��d�G��_7�������wv����=��x|���:�@_\W]����
��H�V�� VY;����[b�Qk�j��#�E��'�ķ{8�����_�͘���]'6'k�m��Ҟu��9��{�m ��͈���c�����QAhc�Cp��md�Y^X�s+�Y�;�򒱑�L#�]m��"��P$�����"O0�=Y]W4a���՗x���	��?(�rA�o)���8��/+�+E5�bDb��Nì�mM1$�FyZ�N˗6��)|:�E�=f�D���-�c�*��m\��2�|f��%�+�1�:E�ʮ��ѕJ��[b*�٩~��"� Y?�Ne;���	��q���Is�,r&�±�z��H��q�o�{��֫����ʴ(�wm*�����2Ђ�| �P*�wP�^�����I*e�S�o��:�XPP]��0�3FP�;8�����+.�{T6�[�.��e]���Pp���m��!]���ɰ�+fȇ�� �+��^%����]Q�$�X3A�d5���g���i`̚^!ei7�]���sO|Fw��P�ʠNh�)RYz����E����������b��ww�y�����^_�-�Wߩ�v$*���1��$��T;׎N�>�ˤaݟ{����Ոn��m��ת曗�+��5߿
7���ŝA�Ru�*�*�
����`��;H�%�K1�>�!��(f�!u�q2ua{��[�5��<�;�Њ��)�D������jCqη(<8��A��:���fc'�����" ;�s�;��v��S�o6Z��ߣ��_��_]]m��kr�C�U��٤��
9�_$�o�PvaK���oc��D��U;˥}5^��cғ��_չ8��֨|�c�T�� ���|��"��D��@+V{<���j��fq�����"��Q̒U�9[���H��X$�})����bMmW���y��p.wO�G�r�gt�p�Q1-3��6��O\�TJ~�;�<
���XWú����y�TPt�r o�.�}�|�45��#����� 	�L�W��vB������N���������"3�c	 �Y��Sf(�6<4T�?���yX!cr����zP=E���T�{J?^Kwj���޹��I!�}�c�n�Ku���{R�hPp�(~ш.بG۝W/К���(t��w*T�fu9��@(D�ƅ����0�D��ng9�=x����_�/�&��ϲ���u�򖷼�-oy�[�򖷼�-oy�[�򖷼�-oy�[�򖷼�-o����Y� x  