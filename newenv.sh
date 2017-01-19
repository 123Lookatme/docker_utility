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
� C��X�<�w�Ʋ���+&2-&9B���sJZj�[��nn�M�,	��}�����7���D8n�������V;���3�+�곯�j�vw[���۪��F�Y}�֬շwj��3��~�gO�B?�< �kz�{����VU}OW�B����c���ܮc�֪���t��Ӿ�����[���ol��kk����\��l�R�g�����������P���M(��o��_'��M�7m=��G����׮̶|F��k���b����5��K������?�I�f���Z`�h�mz�e٠��g����`�S-��*�L�b£(3s�B�������)۔O12� {:E��uךgi�s���d�i
eq�?�76斏��+�-��i��̒%��,I�ó>g��NW�|s"������������[k5��뻍fsgw��������3��U�OdB�o�\��`�Y�[E�FU�>�>T��ǽƽ,�3k�ϯ^���[Ga�3����P�G�� ��->R�(��'���L�!p����1]ԵDXB� |Q׳�`
�5��W������_�X&:�E¡��5}M��%�S�F-�us��I�q�A�l���G����;�(�5~Q�6z��i���m���F�K�HXZ���6�j[H�b�_\�be�ͥ��?:;��H��/8��^V���f�T�"��.��7_�������X</���ӹv��x��q��e�E�
n��<���h0	bs�G��):.�����t�ӕ�����y0:=�1|��:�G h蜝��]_1芰��w��VF��NV!CL����N<+��Xm8�I�f��� �� 6���9ߟ5��p����۱[���(&m���;�g­�z�p~��� ��E��[1)F}�(��߾����?�ї
�Ϩ^hf:8#2O���/����� ��<���аvi��(%r��"��fp�x����q8����.+�\�
�ō1�%�VR_�P���Q���
N+�������� h������C\� �����+�t�9ɦ�9�)��҃�Ц��3?�����#(�$������B�"�牃�;�(�.����c��H؃1˅�� �)�*�^f�N���������]C�5L�-���l�`�����'�859Z�2�ďh���z{Zs��bfk����J�	��(�`���_^�/�H�*�A&x6A�$8'��M�!G����  ����A+��9(��H�����%�Ai��D	`߄�T"���i����ĵ�tm(~�=:3�ȫ���g�-+m:�-0�z%�֬)��CI<�vJ�ǯ ��v�� �Z��W�>�Z�#s��y�gC	����"�%���R�FrP����O�<;2��;�W�Y
w��Su��G�6����V��,�A�u�q��Ǚ��wr���0~���2���;��dt�S�{�c�ܗ�e\�j�w�!�U���ҨH��F�݃	N�v0�e�z֥h4ʇʟ$���k(�V*��E;[[`�k�����+��K�T^1��#�Y�i�j�Z�"�z���Q���AI�,�^!G�,;4cG#��Uī�wGX���X���5���\
�J[���<�,�%sͫ3*S%ǃ�J���k����-���s�����ה�����-1c�6�9n�{ކIA�Fg,WfK�D
+ �V��H�r�Iz�n���_��?q��^o��Q��Uk���nk]�y��Oa�ʫ�Q�a烓�ޠ?�O���%�yp���sF�]x3��p����)`:Ŀ��;x�sw؅w�3x���� :@gt��!D�D��`g�.�]mu��W��*��%i��'
S��cg� z;31_���s��Ӽ[��sǲ�0	J!�3��uG_�;��t�Ʃ�yh�����#l+��eI���Z:jZh,�J�&Md�aD�����]��+z�Z���V�sM��"qMa�0λuL�`��bC.ۤ�����\�l��#���l(�C\� �a=��5d*:��J#�]ل�G�	���	oi����I����.Mq5�2`��0/��o�w�����Ƚ)�!@��)���ߐ2� �=��AC7�Zfin�d���-͇�a' @�V�+�9C��a�i\'�Ŝ�)|��a��opi�AU�,�H[����ܔ��VA�2����0QT�\c�hl�T�9?����#�1��*M���p��c� |n�A�C�%��Y!�}d>�FɊy5�JG1���g��(��$�{����Q[����վ��}W���O���Ȓ�+��J\�V�T�y�NU*����;��~��.u����;��ROcWt�DYN�o��������N���%��!�Ha�5����J[h�&�G��W�ؿ�T�X駳����Eϔ.��p�/�a�ν-+
s.`_H�
�����h)%�]Q�=���6Y�>QꐢX�KՄʽx���(hˏ({ٖ����1 گ
 x,V-DL��W��㈣jh!���!�����8h醌�����HZU�9D7a��T��Z��8��o���լ��H��jNJ��jN�J�\:Y���±��$EI�\Jk����+QU����r��5V�Jġ��9�Y�i�c���9S[nBZ@�\� T�fUΈ<��0�S{����ℶA٧ay��g�$� =y�ZسULX%8���H�J�/��32�"9-�t,	)d�蒾�_�YYM2v+2�6��P�UX{lQ<�w0���e\!T�t�j����2K//��b�4ٸ=��a�X�5_!�6�����8*r,�D���b��|�a��^\��C�Q*_�ԏ@���B�/M�\��:�W�[1v��avu9�v��w��1K1��?O*�/d��nq���~,&ϼ�,Dzagu��.+�/^�Э��aQ�^$ːac��@���!�D�(�'�?Q��7��J��q�0��E�K6Ɛ��X�3�H��"��cK��/W1�0���E�c4y�7�b�<��gҿh
-�A��Z8|�h��U���� 7b:���C�=r���y$��-��i��&m2_��3�U�L*+��Ǟ`me�4`��'[:梚��g�Z�$����Əb��W.���x��8g+m�N+!��s������M��v��X#���ܩjq��%������ ���Lү�<^e�y9�FI��x�A=������d(m�&G��2�"mR�n�0O����%����Ke�VVV��	ґ8\l�_';g��AW��p90^��^4rߓ;Q>��3f;��/4��T���V�*����[>���}��R�m�������ַw��F��ۻ�u��oQ�e��s��4V���1W8��I����n�����YAݕ�(��p�MU���jX4���RB�H���0EU]��bB-Ȕ�x��9E�h�������6�Xp�s�M�V��zq-7��R��
�Y��:����[�2�$K��i�(o�q�n>�AN]��B����e[�׺�����h��d�ۻ��z��z��>�y���*�$p&��bH)�l����k`[T�{��fO�򻔪T�e��H��S�t3#� V~�q#eg��DIW�R�c.�k3�=�G��47P�����ä^�ܠ��Bנ�7aD=��)��9��6���2w �&����&�r�תa^�6f�Q3���̂���T'�r\����2�x����ly"S+�65ם�Fo5�Y
�P)a�D��_�j�*��F�`�￧Q�]�����yS�mN~M�D�1��ߗ�3r�����	q����N����8 �M���o�Z^�i�rq+�$nbxY�\�I��}�&��L��02�]��K�̌!���O�]J�z�{���43���f�e)���*IF�mb䜀Bz�I�d�Bw��Z��������B���S��� G�|�fao�g�(�?3�$ѥԈ����h�aQ�R�3�2暢����\���'9��F����i""�������v|b��bOZB�W�R���� G�,7�S�Z:CN�G+�ȣ.�L��g>�������wJ���Ϡt!9�&D��	�\νV����.��¸&:"�,�O������^�;:�C��,♆���|������t��Kh2�PIZ�?����U��*�����&�!�����诹�b������N��[��\����[t����j�����ONοl>�����������:�{��O�2̊�	&z���{z�Zq��)
B�e�����SĢ��j��ڃ�hæ��E.�{8���?�Xs_ �`�<7S4�>�}�\}�tSD9�F["���H��3N�jj����4�14	 �
	�U"G��	?Θ36R����6���:N���G?�T����mU� N��A�ر"�?������"%=@�"J�)��z�繸��q���V͹X��M?`�Ǟ`@<I����j�j.K�#R88!�E�r�c�`h�[�E�t9?e�tl������kW,cs�(�]���*��b"���d�ym��s�b�/:
��[�c�1����2�.����M�<"���t ���;��QA�y^3�M���P	7Ђ�/ �7�"������
�+ѵJ~�?�e���U�;��`
ʦ�g0	�+�Υ�	�	t�^b�^T:5�ߒ��z%���%MZnZDt��C�t��st'�ޯ���aw�>����WMP?��)ˉ�f!�A^�l��8�}LS�,�r�v�����6��e�b"�:�� �H�u����$w~����=�՚��?v����i�M��2��p�ެ֚�;��1�VH�ّ+��I�!�?�:�	�ՠn��m;6�kM�ks����r�U��H�(��k�c��P*�
_}A?t�2i	��U��Q��&���FH��F]�ޮ���*O��N=���r�<���ؿ�j��Tܙ�5� ���[�Fmw�N��ժ�����D�_���x4����h6B�T��q�V�����<��#�����rʺ��fG=&]%��&�l����&)�C���d���A�V`�K ����
��v�s�f�n�Ǥ'ׅ�T�����5���z@.QG�C�{*���M�2�L��R�����O��+��h��E�1��Tr���l��_ "#��S���d ���F�8��)�|��B���.�ϸ���	�Kղ���0m�BqcP{(f��B�7�7&3���5NO���2B����t���Մ��(pi��
I�g�zc{;�5�����>�<d�m*�}V!C*��M�c�@��C�
^�2v=*��u҃�):t��-|��-�QY����y?���;u�r�|��ч}�kj^�Ks��d�ɠ�ZX�VݜpPͪ�w�
V����)@Q�n?�T����v�v���Os���&�����_�xIڄ����`��w��.�������j��{��m��m��m��m��m��m��m��m��m��m��m���k����#B x  