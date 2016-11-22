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
� �14X�<�{�F����+&2-&yħ�{NIKm����͛�y�,	��I��b��~3��O�㶉��N��V����=�+�+Ͼz�b�o6鳶߬�?���֚֨�Fu�^����z�4�=A[z����><������\�\���������g�Z�Y����t���[ú){�����l��ns�����_�7�w�A5��Wo��+צU�V����f���A��3�<{�jz���ޯc|�&�,-�7m�C�����N��|A��	.5{�P-}��;�F�t�?=m������:𦹆�44��U�2\�1-Ж�kX>��+Ѝ�����2�b��(3c�@&������%ڄ/14��{:A��9��5���%a��hdQ�%i{pуA��	䨮g��>���o��qn>���ѳ���6���Zu/������4����� j2��D���V��R������}��~/���̜����W�2��Z�A���Y�z�Y�G�OH��p1�Z[-ZKL|Q�5-�9�Subc��we�|S����c�"6P����I�� �i��X��S�$����>����T�����l+�5zQ�����y�w�ij������ ��=m�ohK솀��D;!���](fb�������Q'�G��z��xZp��䬊v��h���/Z�r�'�ϳ̠�d�N��B����L[�S��C���	ݦ�Y�Q�E����_�o|�s���?���G��#�ς��n{��	j	��4apުm4%������,����&`�=8�މf�P�u�2���c��	`	;�í��@E����GO�ѣ��n3D"���'F(w.(�m׀��o�?�����#<�kpSĹ􅬤v�z7�4:�Ko8��%�Q�ݥ��D��H<��s/sl w�GC[�1;�a�ݥš
	kv�+T�Y�"�e����>=_t?�W���d,�;��Dvc`v����	�J�w�=u�Z�e�Agxqr��- ����~�:�A����Q2܁1u���l���ޑ�MͿ[Z6޹Ƈ��"�d���8�A�a�~Y�N�^�����$�sdk�1$f(��X�JN@�ْ�f%�/3C#v��z��<���s�����q�Ĝ��ے-ua��1���G��#H|58گ2^9
��ql�h��ҜsI+�d���q�h������^����r�$��_d��H������|(�ٔ�BdL���v�R����d�	P���x�k����@`ߘ����몫�G^d��6�6d���r�UL��3����&7̓^	Ú9��K(�G�jAA�����3�JXXMt\�.އ=�}eƘO�ZP@s���~�<��L�JÈ
"�P}(~���Ԁr��}Z>dy����O�!D_K��/2]V36+.S�[�0P�-�=��m�:�0�������N���xx�S�s�c��׮�O�?��;L{}P�2jWM����?�����|��2ܼ��T�C���M��U���E;;;`��������+��K(�^1�#�Y�h���j�$�z���(��� F�[/���a��4BC#��e�[��E��!M�K&ao:�v<�Y2Y`K�g�R��R���{/��q����9j����]V����*g�2J[L�B��eP��Aӑ�9�B��A,"j�PE��?��=q�_�5k�T��QÏ<���?��G�� '�e�������#Iz��w��bA}���p6���sx���?xo�:�o۽s8�C������3�`����p1�`�ުL����Q1֧�3��tH��<Z�thO"@og���OP`n^���B0�q,����H����to�'���7�SM�pim��Y����Z���â$�y�x@)�w��y�o�D�����m.x�ҡ�)&�7���v�F�E����]96F�C�BC*1��M��F*�w�.����h�onE/�G�0�#��04〻S���%��W^C�-m؟��|:Α[� ���hHu+&����5���L�vWk`{���ܝ�p0[��o<&a�{���������F5H2K����3��0-�K6m->��Z�a��s2��9z(��9��<�r���#�lazz4���vA�2���� ��o0�0u�g��/�]{��Έa=�c��T(z%��6� Сߒ����>P�h�<qG�Ǒ��B��"���$�呸�Յ����w���U�٢�j��$��x�h�(�DEF��QAC$w���q��>�
�ޯ�X.�F�o�ih�.����k|�>��{�����΅fp��TXF��%��j��8����%)��-1+����E��h�-�,c�B	���p�ޒ�ED��s�kDD|B�"�(dO�=V�*�(ʌa\�I+��P��Q�"�`��%�%B��c��_e���!wX�,0):�Q4�
g��0� KM��x�����|m�i��Me�c4�fMT����r*ߗ�PKfT�@t��J�'j�ȸ��� cS�A
�_��,6"�A�W"��� �� �r%�R|>pg=&o�R���2�>Yo\3��S�2�ʜ@�L�0sB����?��,]���tJTt�u1˳]� n_�����m"�&Ɓ�U`����32�">��t$	.$�)�!yA��YY�*4+W2�6���MP�	hA<pp�3���e��)B(��X�5��1d_^ǡ�q��=��a�Z�5�!�6E�P�8(2,�B���fv.<�a��/.Rȡ�(�+��_��D�-��\�¨:	W�[�6��arw)�n��wz������GߟG�Rc��+�/Z$����5n]�^YI�&����ū���m�|`�B2h�_@�)"H�&%��'���C-mT�GiX0yM�0�"dK|	T �ih���ra	2�yx�<�&Pܱf��~/��K`h�B�V���}0E�<���m�/���;8Ϙ��H�=�P$j�.��.��"m3[��*2&����;��7�٠�bk'"T~��S+��h}@�1�9~d۶��q�=H�C��H���:؂�$68\��'�X؜��'r�%��C�|Hһr�
�1D�H���_�S$Vc��W�=� ��|R��6�R�&!�r�72��I	L�P���L�i�W%tIڦ��Qo�"�VkF�C�;�G%(���2�XѮ�7�G��bbnX]�_'FJ�{2�GP~�|F����}�2�ض)-5ࠔ�5TK�w��\�y���{�MV�m���kt���h�����ߢ�ˊ��tQfTa<a�p�>�W9���O�-�`>�ÛJuWV<��D�/�ҁ�9հhaQ}���3-X9�A
��hEł��(y�Zs�&Q�12�٘ˇI�*�Xp�sэ �v��za-7��R����Y�h���ޛ�2�$K��L� o�q�n6�A����B�M��2��u��Q�?���5~�{���E��՛��������B�}{L2����o�/��C���i�g�@��ߤX��%s��]�-��KN��X��Ð��!�Tp���4�PIA�)"�FB	m颫��'0�}�;�T��_�c�܁��Q�g�JAD�ZIu|�B����$�^����H���k��V��z�/�￧QZ|���d-�;Ac��xV�md�����D��(�$��1�,&*�r������j"
�aܘh��<
i�P������72qC�b&�^&Gq''���o%Eͽ��J��e),8���,1���J@�"�p!V�X�n���G��[�;u�b-�h�H��� �sxφVa/*�&�(�73S���^`���$�B�=��(�����6#�ˏ�'L��`�<) �H��s+�#<���w�o���;ew&�lI�J˔x,�k:��mҙk?ڡ�Ct�-aҖ>#i]�'Ggo��2+��~�љh9B�Э�v9����=�3��0hC�9J����d9_=O�
� x%��K#���*�Գ2	R�:}��!����O��l�L��7y�ow�Z��k����������������a^�����������9��������>��F}�����n#������Ǻ�c��u��{z�Rq��)����
b�+z��yK�3������eQ<�<��}7����3&�9S׉��u�>���E�da����ak�g C3b��𘣳>�1��|Nb�m�8�U��8E㘅�/g�)��4"���)��E�4�e�V�	�'�UY�F��A�XY���[�@Y�c�� u���H����\\��b�R��T̀H���ٜ5��1���(Oߩd��:�8 �O'`��/�}$Q�-�@M��H������ �1�;�y��
ỵN��k�bt�\&=cK�E:;֯1Rd$�שl'����
�(]�L�Cd�3Y���S'F|�}sa�K���W�ogT|����ӢX޵������@�� ������
�J��:~�>I�l��]�˹�2d�EW�1�;����	������
6�[�^����*e�!��%=�n�Et��Ct��}rg�!w����(��{�4���7E9��l�����
��&Nf���5�B�Ү�L;�Q'>#��u7LeP&���$=�ۗ�����i�
�D�W��g����6���)����^Z��[��JT�V�cR!It�?�v.�^mC�I��:?u۽1��!��Q˲-�ת�7�+�ʊ��M� �.@q'P�Q]&�8�B�«��?r�i	�RL��a��&���FH����h4�{_sh��wg�.Z�K9c�<�������P���5� ���O��~����7�����k��� 쌟��6��������G��z3���<��=�����zʺ��&G=&]��M�٠/���MR����`������L��֦l��W/+�^�=�۷��u�&=�.�U���In���';�L%�r�����W�2=�5�\
�~�b���}�����+�U�1�=��&�,�U^����?�Er��E	�m�����H�@�������J�>�.�?ʦe�պa��ۀ�C90�S<(r���\Wú��鯺��Pt�ro��ݼ�}�l5���x����B����Vo4R����~��=y��H�U,D?��"e�B��i�����Wa��]ȉ~j��x�NM�h�naK}U�B���ɼ�U�ҝF�~�w��{R�a�����R-��m4(����Dwl���N+�The�h	P���;�o��{��"8�W|�۟� �Zt}����/߼$mC[^��p��wf�B�������y�����-oy�[�򖷼�-oy�[�򖷼�-oy�[�򖷼�-o_��/�t�� x  