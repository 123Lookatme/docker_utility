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
� q�2X�<	xe�E�E;x����~��6�$3��M��P*m�iB�$����� �઻(�x`��U��Yą�E�Ee�]u���UA���]�������Q�e5�<<I����{�k���e���r8��q���&��U�Xh�j��6[�Ь�R�le�p�%�*K�����}��Ų��e2Kb�<��':�;k�v�0��=��/&���V�
�&�{H�oc����1����!����~U�6���9�I�T�D���V����f����i1�#��3���	w&jk�t",ɄFCQi���]�v��D�(Q ��ǹD$���%)������6�:)
!.A�yN�1
'2'$xU		N�"��QDQ�E�(���j�yT�����|,�*Q4)�6@���U�h�c|XF�n�[B�ˉ��R>N�"�AYI�(����E~_{(ŉߩ����P���������i��������?Ϛ���'�H�gtHHPؓ����T&��;a
?_P@T ����ax��iٳT�q���E:!㻸Rs�1RGB�0u�X�?%�U�1Y��ą���*(!���U�^�@L��<�� g�08nA�m�g�ʛ��mno�ǥg�r��r��K	�x*��P��
y�Ԍ��ono�ՑQp�S`$"��*��P�pG����b�k�.?'���/v`�Ec\׷�]Ft����[p��L���H��ne��摚�]@7��r���'�Z������[��nnr�� g@��6�os1l��X!�M�z����olża��EDI&x,O���8RB �X��nā��$T؅94d���Y0�8�PU�]�ȘB:�ȣ�dIi�?z�� ��)��P�hI[˨
_���� �	����À2��%�i>oA�"��;Q.&ݫ�?���8\$�鄂U� ��
�2��
�
�.�[q� �Z#&�.��(��M�m��N8p��?�u�S�� �1�1|K2��7U����T3UUHp�u�Y�������PGl0#5��
�.B3��6X�a*��'�H�o,Ϥ�r� �ā��+�.�I3 �⢁�Yih��I����������ghk+��Zl������S<<^h=i|Sښ|�V���� E����<N��b�|M��Z���\O}����>�t4m���A�}�h��ۆ�|��Ѐ���Ǐ�s�����VT�.s4�u�8�p��h��ǉg���a2�E4����_���(&�DN� ��^�]d�AT�૟��Olj��R
sӡus	8:KGH+��Kh��VR�O�����rp�#�:K7�D�!J�6��b:�'��4��b��H�Щ���(TbO*	:��`���_!TƓ %!�� ��
Ch�h@�uA���1L(�ΥL'�A.&p���;)��ۄX��=W<��y��|�D}Q�jP$�D&����f
�L����+b7��!:JL��-H���N*ɹP������d:�<ABuW.�>es�*%ȼ ���iP���)�
�Z���v�Ц�ꗰ9�W>�+�})���QHv0���n�x�-��㝪���3n�]�4Cm���)�I��;��r�ՙ�?YҩMI�x��
��'V�)�
Wś�=���3�l�p�bx�ԃ���.����N��XbU��7*���3��J�d�N��
|�q����t�wJQ �:-�ng!t��nN�M$!!$Ӊ.�#�(B���C�=7�Ƚ�8H-��Y�=�D�	,����S��,̈<� GN&�#d��	:��Wf�H�P��#PFg��!��YM��ܺ����#��V36�TPa?��1��j����RZ%���nܓ�8(LV+)��0�}���qW���ǫ*��w�:Q>w�nk�xq
t�L,hJ-���T(�U����B P��2j�y� H;�Ɔ���Q6<�
* "�3g��q�O`�g
#��S
7Y�f�a+y�rPm�*�t�����ܧ�܂�}v� ��l����8	��HB�s���6&�����P��g�vh����ZqP�������;�����8���?�8������v�G�Y��D�L>�b0t��Qy��(h�	���4x���pw�M�"s72�e� y/w��'���y>X���&P⁬"�@�I��A�S���2�H�K:pb(��пfZ��L�֐�8 7���eD������X�[���ٚ ����b!g�C騜WY\Z7���9��b=�r��9@o*��?���V���j�o�1�\�a-�������O<|����.z�܆��J�w�S� �? ����>����:����N3���_���ۿ�!��%�$�!�럱Y-%���'y�
�*����_�,�}�B���0�A��C����������M$q�td��.�`/����k"OȻ�;���4]�U�x�p�ga5�Uq��I?�4�)�'@�ώ,���翙�_�' �p,#��HA!�("��qCpp<�����C@�?�����Q��0q4r��}�ں�{��_�陵Q�Z�qi���/���B����_��bO��H&���ԦJ�ӑ�w�D[�9������0�ăC1���?P�q�!��X&��x�����{}�T�{G�N��K��G�#�{�y�}���U"�Z�iQ�;sb%e�g:UL?�&�R���y��w�g�����D�I�$f�|������.�(�1-cN<>��Wَ�b��cr���q�.�� U��\4Ck��.vWD|�K�#��3Vь/K�Z�7H����	��¡E��%�I�D+��Wf/Sȗ�g�o��)[��Ѳ�)�>���=�:�6�(~O\L����z�RW+��<n`����g�=�33k]U���L�X5�SλW�DR+�<~�g�h�	��>j��y��q|��q/��$�L����>6q�W�TҴ�ǩ0���~v]�N�룐���i�]��:*@S�'˂%jt!��\���%b�C�!�*�SS ��z���d�0��,�|JN�<��nev,�|�yͮ���ǫ��1���[�t������`]Y�ӼǤ,��+�h%���3��^�o��W�%3�"�ϗ��ir$��*q.������dl�Ch�f��͍#L�;���E�ks� %Z�Q
	�m+�& ]��;�%�����
�������G��"3g�E-�����B
Q(�Y(D�������T���'�Aՠ����rY���N����כ&����f����i�
�[��x�$6�"�:��n�\6�!��U����:rg�I�KCf�_��*O�W��u+�t����P�<�p�>�P�i��W�1�Ϡ�T�x�����o%��%_�3K�9��N[yFQ%|�������*́yGFr�i�Bb�
��5��w�V+��w�#F�NΏ�<�p�j��_��y���zA�֜�9�>j��f�XH~v�䉙c� &;�c��k�O@K���D1��"�]����@��~���D�]Z����{�Bc܏�֢߉��ݞ�-g:��;)�f��uE˿x9�Y�'����9����)������so�|a0�= ��E��L�0�I)�w����ç�O�= �&���t(�l?��VTA׋��l-�^h�����U׍�Hc�l�WI1�t���KJ��������z���=eX�
I�
;���
�-j��Q�+��b�[/>	`S���Xپ��1����1������׸;E�K4d/>Z�0�,��k���b�{��0� ^��B0C�6rH�)In��B4�$ky��,5[�*J8���ts����l��܋ȿ����*�(���ֵ��ÉVWL���"��ͪ�#���ڃ��Y���f�p�/�����SP!��E�V�
08��ک��+��z��Ѥ������������菀bP0E" P(��`(8�É�C����y��ZV���;x��G�)���Z�eu�E9C��7�/5���H���4�Hh5��'.�a��I~���P.>x����gs�3MD�߇V�7��&����)JcNY܉���HE��@��)�x�pNQ��`%ao����=Z9���)�����޾`�R�$8*��^q�Xx��I0-n��
��M�!��6���6��,v���E�C�i�&��͸�sM��c�ɛ�ԅƐL뼮�K����UTm@��)���E�;�bk��I.&]��i	���T��
�c�Ž����+���@m�KFϫ�G�r.5e�lyD�m:�֟B���w���Hj���.���/�{�����wۙ���(̌��/D�暯8XmQ��4A?���>�]����u����}[&�M����<����-�b�tE"]R؊Bt�Η��гG��Xϖ6i�P[�_)d~�,7^�-�ې��ޣ�H/�3y=�!��odL�o�w�c�hh̺�B��|��Ŗ�h�� ~�"��U�,[e\��$>(��e*7
�6'��kY�������x4�`rtH�������u����Z��	�,ľ�F�}��?���#��A"��N�8����|�\�x7}���z����@E�,�ٻ�~�'z���f:n]��� 8�0?'Q�s��������hZ��ᳬ��yBc��'kض��Q$@���Wߖ�b�T(`J����_V���Ž���/��:�jK9(�%�(8*꣉$!�'�H � ��"ku��tAwUSU�N��.�v�eT��(� ~T�`D�EQ�����8��W��Y���I�i�彻����5ݧ�t�|�U�>�����������<������ׇ,]�a�gv��kg~�I�NO����[����j�~��/�}˶ͮ�.��>�����m��Fy�8��Y��5߼rۗ_�JJ��tΒ'�>��N�fQ���o���ʧ����1c�����C�MU;^����]{Wx7�s��S7���u�K�ή}����?�J�&�n| ���
_��+�g������!]z����W�\>m�?�,�ɡ�F�+��S;�]^�:�Ŋ}���^�s�ց�>�z��#��������_�������z�Zu[�9Wq-��zgw��s?�,�sW��
������BAO�����@)%!_A��z�O��_������%�?I���~��>�ݫ�>���P�扳�*�H�c������g{�mi��z����N�o,���_���v��~�����ڗ.��ݣ�-i]�f��?L[�S8��_�x���.���?��G�#>~�!G��²�����q���=����[=�v�~�h�z�r����iߜqιeKZv�N���JH=%���o9��g�X:U�����$�����_RX�h�X��)����}%^_��-�������59��_��ￜ����[ߚ�������~qך��:��H|��}�����?����m�W�{����>~Ƃ�3�����Ӿ���sz�͹����cw��^�)�ܚI�ƨ[��.�����G/~�{~��I��>��o�����iΖCs�-{�c����>��~o^�I�7~f���������%��]��M���������uߗ��u����}�����y탭�7��=�Xh�T����g��p���6�\�W;9�չs���e�/��)Z�������o�s��-Ks�_:E��Q����?I��PqA������T���D�,���I��|�_p"��z|���_T�o9�s��?�����|�����-�~���M���o������/�k�1�p��2yŭ���>n��F��}�������%s��'Z��=���9����:G���:w�;�f���7'/���`��Ft���9sv�=���P��Q���+����.O_zp�軟>gފ{^�r̈իVH��j���=����^�鴋�o������?���~O��-�������F�b,I�D#v�b4�������_��|����u��Ȋ[݅�\!��i��E=��1�*���J�DX4��1���� %��{
��)������Y������E-���:�#b$B%�v�+b���D�j�Q
.�"�# L��1� `��`2 ��9�h�3&j:%N�)��lR�h�[�G"�W��+ ZE��5���F)hD���;��?rnRՋHr(D̑,\FcF����ei8�bc��`��JDO�ʱ@�X*,����x
��, ��!�T�L ��FM0ٖ����d�"�:��ƙ�A�. C�C�f�`��e�4+��U	�5 ���F�uW�q����J����7ݐ����e=|8�BSu��"�R�(Ųb�T�ٵ�,5GvoKk�� �;�� e6"I��F�k4�겡jIM��bU6ث�����)�`�D�
����=&��¢��"E��Թ�rD�������@ vҭ��Q�v2�-��pՠ)�QC$ ��PĨ�q�.�LR@=�-a�Qɑ�l� ����8�Zr� ��p Gd�"��T#�T�x=�:q�u�y���:�.+Af����qQ��°đ08  0!���
*Q]�Q��$N�K����[�g�3(�0��D]9U%��k|���Jˉsɲ�`#dX���a�J+�i�D���5��y���g0��1�+���g�������j�H9��(X��]C�!H	�r5Zz<-(����@�QS�LwI����U1&�
Q���U�� �ecd�ZY��(\(��~9Ewd!�P�����wH�d�`�ip
X	�%�d�a3ȜW@��XT��#r@�DX�1��(@��͟���B`�HNJt:���r�[�vʊD�P�Ȕ�S�u:[~R�ԯ��	�3�ל����Sд�k9�qJ�ܱӹ��5�����H���T��2�MYG+y~ I��ɘ���-cl�@�B��q�IǮ3����I��р�ӓX�y�M뿂���?��+�XR�k�ɁT���:��dH\�URA�QQQS.lO[���.��2�
i�H��� 3�fy��t2Y
01�3c�� �I�:��S('	��,�5�f�/>8�Ɂl�Ws�0K��1�g��5
���*f�zA7q��"m\�ʾd��L�\[�"K����0���BA�L��R$MJ�T����즉���У�'�7�@����(,W�S�Afؼ"`�qì� �nq�pY���;����
n��Pn���n�^�d^d�R��Ed��`KP]�l��D���O�p@���`��̀�E�a��N�̄�� �}Z����(b�
��PCN4+�!�����6�[,2yeQ۲���`���Ve,!Fˊ\����E�-�0
MD�g��
��1�R1E������N�Wxpl�Ȼx[� `4�-��uN��E�P,5gv�Y�X��P���FR$C� �b	"
x0�7�߯I�	�q���
������?���n^,��Oh����?>����ςB������������?h0,�5<��G)�����ᑐm#���CQ< ���<5�0QI�, <M`V%�\�$k6��5�<��
<�{�,
R���̺�ânL���
��ok�3y����cŌ�3�$�F��Q��ѕ��I;�!�.�Z9���.'�w��Z.|�"L+�z~� TY�M�%�u�0�'b�_����C��
���'<2��=�,���O5Ӻ�� �"Ó^���9=
\�
L�^�U�e�j�vX�f7d:��;� �CU}���5������/���y������> ԑƸ#d���V�,�}��q�w�\J���t�!GB��/�v�o���6*����ݨ��$�c/'x_є���{���Miaݥv�h�m���k
ʊ�ʰWE� y��=-�v�Q��
M���+���x�����9����)��H����, 5��!qS�zJ�|hhH\�j~Xb�U��E�;H}�+� ;>�l[hL 3J.Ù��K:���PJ�\V�d�Q{��W���E}�&���K�=��17�TBԊ�&�g޾$�̖A]7Z
���Fͬa� U�� ��<��a�\����m$�s��*�+���w`��X+��P��O�­�D��au��
��yF!��2V��p��$�1�]` �����*w`�����1yx�$[����{Ĕ��,���]���(����қ�ሖPt��)qN�"��v���TU�����{Pl��8��I*��
�T
�P�3�U�Dx���oRi��$���Pa߃��2��5��x�0���V���k2u�;������N1����&�ԠE�*����)-�8�
�	X����&���`mo?w��I�[�X"��3vr!IwA�[�ݷ4��-���⭂^-h��B~<�3V��?�S�?�5��W�7ֲ}G&�q�n5��݃�7���!ʘSO��`�q\U�u�Ͳ��I�Ms�Hjn�x�Nm���Lr 0��N�K��(D�ӱX��/$�<4���9pBe��mv�¨pI#D_�5]p: ��; @G�^+��	�Z8p��.��S�xS�
�F�_`/���6���Y$��:�����y�S]�e�
ǒ�#�e<��Xd���m�#l�2�:9���$����?`�����J���ڦmU�Z5����7�8qe���ܖ:J���G�:�r�w ����U,3��R��D�,'�!6�"W��q-�a^ �t3Og�"3,�K\�3�����=�eD:-��c���rN ����R�N���l��r��.�sV_�u���1`�#�3Z|�1�@�O��9#�E��!#�PJ�t���'��yVX��ϯ�\\\*�NM/���:6f� ���έ��C�L�Fb=��Nb��Ǹ�/:�ֹ�7kJ���9z�.oJ���ߧ��������m�����D�}�{�$I;�@H���#^�����/�I�`��݊K�U[JB)������,�^i���B�S��NĆɒ
�oZ��4�^8��VA�	�m��є�Ji8��]iG�[��+�������-t��h(����!��D�t$D�h۵��(��(�<�&�����J2�[7�;��{��sܖq�N {�ȏ����B��ߛ��)�$?p�B{䔽Î�0�wf�*���0!.�^�~e �/����C����z��8P�������Q��>�_m�=���XD����Ӭm�L8B���fG#�1�9��?�K�L����xn<����d���H�Z~�,��G���ޗ���G��h����ja�Z�"]�����>G����/c����#���-�on�'��d����GO_�?��������B�����*����	�F#�������d��47����?��Y+;M�*�ت�|�a5]��*r6���p*�Ei�6�(��W`�A��4�uL$B[��*�&c�u�PС�v��n�Z��D&����H��F����\3[
Sq�׬f�ݢ+�?SJ����D�m�!m
���g��
Y���Zު���GÛ�ω��*gd�tE�^��g���6w��L׍UͲUd<�ZHV1�����(6�&���b��N�I=ᣋ��]s�x�IN۾V�t�{�����u�Vz��O
�S��z�,�-!̯#{�|ے�J��W����a��s-!n�
cZx���b=�8ݚͣ7::�5��G�����U�O��e /%��Dn��7
U���Ӫ�fSdSzo x�'"���ft�[���*�.B��M����Wgg�M�P��a �mk�'�q���ʘ=�g������(}���S������#���8h�<��g���M���E��_ȏs��l!;6Z ����|���[��8�a�b��(��x5��k�]�"�Ҥn�,�w��u