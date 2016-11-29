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
� �G=X�<�{�F����+&2�y���{NIKm����͛�)�A���D$a������}!������� ������ٕ���Gol��U�,�V�Oٞ��W��wvw���J�T�=A[x�����?����Ж�=w�?�w���j�\,V��X�k�?�m�ڴ����/�����_��+;%�����_X�����s�Ҳ�KÛ(�o:���>��i5:��,܁	�V�]��k���}��=�-��Phe�c�����pi��3����;�z���>>���{�`����5ߤi0pl߰lӅ-ˆ��uMۇ����͑����<tM�b��is:�,��!���K �_�kŃ���G���2.����&
��YEU���Y:�S$��p=�/�	�����G�����Cτ�/T�e��r���������4o��3��ᙠf�*X�B���S�R兦���}�i�t���������W�6��Z�A���������O�"&�"��bԵ�Z�������k��Tk:5������;��V��^�(-c�"6P���1P�A(�Fѱ�V ӽ�܈o������}{^�����S6���i��ߨe������%��Ҟ6�7�!vC��FI��.4+6Hx�fk��접�#ͪm�9��܂���.��,�|s�v��}Rda�<m�������. �3gv�iy
�tH<���0thyAV|h�6�̓��/k�7>]�9��������A���9�~Ԭw0��A��&tNk����}�� Z9���<Y!�;�]�;�,
#�бM�7����a�D�N�pm�0���l��#�����`c��B�L�����;�9�uׄg��5����Gxsd��M��XI���}��l�νn�~� xF�wf�C�"�ddL�ԱR��O�`�G�t��v6�*$���® P��3�Ft����Cr��~�G���dI��-�@vc`v	����s����P��J��=;:��.@�����J��iwp�>J�[0Ǯ9'㤚�븷$�Sk��.l
o]���B�@2��s�� �Ѓ/ ��r~9���A|;�����=��\�1*[��,��eb�]"���#����9�����q�Ț��[Smcfֈ1�G��'��CH|59گ6��h���b8�raM��������ɸT8L�XG�S/`����{�E��/*�g�U�SR@a��r>dJlJD!R&�Sd;N)�i|BR�HTE>�i��� �56����=9	�p]�F��M��Aӆ�7?�1C���(f�°����f�y�+�oX�Fp~�j5�x��b�1+� ��K�Ň�gd���s��/\2hnpcӗ�[L�!�qNi�AC�g��ϟ]���o�ԏ��,/����9�e��i��LW�j֜͊���Vٗ
�E�'W��p�*��!e��h��z�����j���X���k����-��>h�<jWQ+�ƿ����A|����]���T�c���M�dˤ`Ţ��-�j�W��j���%�r����,B4x	�|!c�y����l%� #Ff�[ϑ��a��0C#��y��wBCX����֜K&ao�)T�ly�G�d����5)�(L�ʹ�wЕ ��#��.���sԌ9��~;/h��{y�O��0eT6�:n>oä `#�2�\e[�H
- �V���!YREQb�?��=q�_,V��D��\�)������S�xT^;�9i��'��v���(|�)��V���T��=x�i�I�����)`����v�=�{��4�}���[�pچ��P��C�r�v�8�60B���tڟ�Sҋ�sE�'GK-^:tF!�wC{�4�Z���ޠ�q,����Hf���4:o�G���7�S��a�҃�b�R\�ږ�VV�������F����C�I�vR�ns�;s��b�xeLQ��{����p��D ��wo�F�E�C"1��M��A*Y6w�.����h�o�E��{�0�#ڀahE7�6��KHc/���;ڰ?�<��t�#טA���ѐ�"VCa�'L�Dǳ|ǽY�r|�戇���"�|7�CaK��rT�!��$JmT�8���ex�;0q<�<pa;g�zP�c�Y�	I1'c�|����87� ��v$�-bO�F����.]FR��$r���֐홲��C�Y�[�ǰG�n��1*d=�p
_�p��oE�cAr/Շ�(�1Oܑ��qd�(�P&�HY�?����(\d�O�l�������{����j.��&�x�h+�EF��QAC$w���a�U?n�2�֯j_�F�o�i`�������R?}[�<���~Q�B3�a]V�pxI&��n2Npp||N	�kM̊ ��|�<:�@�"�H��P�m0(ܸ�TMc���\���.�мk����Y���2�E��u��T�������}��˚ʖl_0�M"�2���a�T���|G�8X�R�ajA&6�>O�|5}�b�����UV�	�L���52��������k*�أ��#Y�L�#|��W�(�B�R�̽�U�Eƿj&*YlDD�z�Dʇ��� ��C.:��N���D�|��W�q��i)k�N�b&K�9!������}����Y�CJT���b�縖Iܾ�G��=[E�U�1��a����32�">-�.ħi� yA��YY�*0+*�6���UP�1h2ػ�L�y'���|9V`MBoaǗ�qh�Dmt��u�.�y�w��MP6P�=�K�P�e���3c����Y
9��r|����,т �gK#0g� ����ֆ��e�0���@�OO-��{pL�Rǣ�/���)�9��7�_�HK/`�k^����MT���W+dK����I>�i4�/ H�$C���Iq8���1w���
���H`B���t�c+B������'AI�OB7���K�Y��Ã4��$���5>��[��O.��%��X������q|��#�S�f�88cХ�Nz�HԖ]2�]x�E�d�2�c�UhLr+}�C;�b�oX�A�ŖND����S���h}D�ы8~dۦ��q�=�O���H&��8؂�$68X��'�X�y�:�󂛁D�'�M
�#���K$Z����)���L�ˋ�^��g>	�F	��x�A9�霵���d(dmh&��4�Q	�S6��s��z�՚�@��QNJ����J;�����x6�T@���ױ����ho1�����>*���8�����K������ʫ5�R�������[e���Nq�X������������b�9]����ǡ=����*gX��9��)��0=���Rwe�3Jp,t�Ѣ*� �R��WJ�=�+3H���VT,h������5�h�#����|�T�D|j �!��xY/����Z^��X�`�#�����[�2��*��L5���8r7���F�k}�ۦyݲ-��n~?��gy����Q�A�/��\������P}��LH�P"Y�������24���H!���T�T.�_%��)���H1���<t���L�(�j#�s̙se�=�Ř��5}�p1�~����b>�{a���b.�)�T6e������)��W�kWPz��+�Ƭ:'jF��=���Ͻ=]ǅ�|
n|��-�he&�j��ՒHFv�l���F�j��;4@�������5�?����P;��hR����E'[h��Z�G��l�����S�2�����q�C��N�rϠ  <0��k���Q`�g}�x�_��/��?�q�`B�BB��+����n;	P�50����yv8�6b��"ĆL��>��R��3رɞ�>�m���g�x��6�`7�AQ����rQD�2ZU6g��V��r�,2�ݔ��K��;�q1M��J��:��S"1uLl�xUU	N T��LUnbDM�:�	�bjOW�6����a\�P�����;a��*S������9�C�4ob"f�]LIs>�V3%b1Qҕ"�Zb�Ro���|�̢*I�6
��.<W�5]��C��F�q�iv�%ʡ�k^�,��92Xc��E��tŏv8Bt��g��<��]d�G'����	J���yu>D.0��r�U��%z(RQ�q�8{aI�x"��x���5�p�}��`��h1�y���R�ԙ��`��*Ê�$����k	^�
��,�O�yf���Vv
��N���Y(���|����?��>N��������*�P������?<9�������n9��J��~����?���1+2��������6��g�ݩ:RyL�=2�2��B��q��(��L��n�������w)ٜ�;��Iu�>u�_DǤa���=ÖOA�fDp��8Gg56|�CZ���$���+�#r̂��gL)���&�ULu��8Y�4�y�&�nOf7���{"k v�����e����@I��R|K �އ�y.�xrX�_�]s*�@$BO�l��;v��~��Բ�l�K�Ƨ0U������P�5�@O��h��qG���1}��]�
��ǩ"�e�F��|>OzƖ��Bx��%KlY?�N$W�<
���c�b�,:'�±�{��L�8зf���ke~E�zB����pfٔ/��p}�_x)hA�����ʈ�A1'�U����I"C��r�YL�,+BF����0b�P�t䙰�_a^�����5|�Cנ�6`��Iۍ��N�ph�.P׏������F�-���6ݫ�Y?e�˪!�&ƨ!Y��il�d�p0�X3��v�إڙ�:��e�;b�21�@D�rʳu���_�o>m�O����
�]��v*����4����ra���b%_�(T#V�cR�(�fG�d�.��C6~n�[}�Wc�����L���o]�KEu���M� ��@sG�_.E������m��1'�!�� /����<n��)m����I�ۀr�����9������D+z��LQ{���7��`bj���1� ��_��n�H��Z(�������P`w<*�U�/U*%�*��b�T]��O��M�}}���.e��QIWi��~6�������A�C3�=���fx�ozKSVo���
��קS�-_7kaғ��_�X��rkT�����(������M�2���1�R��@�z�����M�GKB�냋�c�{D!M�i,ӷ�J�?�D���">�k�@��CLq��=P��qx�߽P:�����e[�Q2m�BqcPz(f���Bn����j�W�<�U?��n��M�Ӡ����o��������#$�_����r9�U*������?�Eb�D@��)Rj(t�j7�T�"����Q�O��a�����t��V����Wmf�趏���Y�,�9�(�O���ɞ~ا�M�Mt�AH�{2�p���F����uA*����h���շYَ��N�+N��ߚ�ø^���p��7�(�Pʗ��\���i�#.�|�$���:�^�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[�u{����
� x  