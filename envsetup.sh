TOP=$PWD

export BR2_TOPDIR=$TOP/
export BR2_BUILDDIR=$TOP/build

BR2_OUTROOT=$TOP/out
BR2_CONFIGS=$BR2_BUILDDIR/configs

function insert_path_f() {
  if echo ":$PATH:" | grep -qv ":$1:" ; then
    export PATH=$1:$PATH
  fi
}

function insert_path() {
  if [ -d "$1" ] ; then
    insert_path_f $1
  fi
}

function hmm() {
  echo "Invoke . build/envsetup.sh to add following functions to your environment:"
  echo
  echo "croot   Change to the project root"
  echo "lunch   Set the architect to build"
  echo "make    Make the build in the correct directory"
  echo
}

function gettop() {
  THIS_FILE=build/envsetup.sh

  if [ -n "$TOP" -a -f "$TOP/$THIS_FILE" ] ; then
    (cd $TOP; PWD= pwd)
  elif [ -f "$THIS_FILE" ] ; then
    PWD= pwd
  else
    local HERE=$PWD
    local T=
    while [ ! -f $THIS_FILE -a $PWD != "/" ] ; do
      cd ..
      T=`PWD= pwd -P`
    done

    cd $HERE
    if [ -f "$T/$THIS_FILE" ]  ; then
      echo $HERE
    fi
  fi
}

function croot() {
  T=$(gettop)
  if [ "$T" ] ; then
    cd $(gettop)
  fi
}

EXTERNALS=
VARIANTS=()
BR2_COMBO_LOADED=false

function add_lunch_combo() {
  VARIANTS=(${VARIANTS[@]} $1)
  BR2_COMBO_LOADED=true
}

function _load_variants() {
  if ! $BR2_COMBO_LOADED ; then
    for variant in `ls $1/*_defconfig 2>/dev/null` ; do
      VARIANTS=(${VARIANTS[@]} ${variant##*/})
    done
  fi
}

function lunch() {
  local variants=()
  local answer
  local selection

  if [ "$1" ] ; then
    answer=$1
  else
    if [ ${#VARIANTS[@]} -eq 0 ] ; then
      echo "No available variants for building..."
      return
    else
      echo
      echo "You're building on $(uname)"
      echo
      echo "Lunch menu... pick a variant:"
      echo

      local i=1
      for variant in ${VARIANTS[@]}; do
        echo "    $i. ${variant/_defconfig/}"
        i=$(($i+1))
      done

      echo
      echo -n "Which variant? [${VARIANTS[0]/_defconfig}] "
      read answer
    fi
  fi

  if [ -z "$answer" ] ; then
    selection=${VARIANTS[0]}
  else
    if echo -n $answer | grep -qe "^[0-9][0-9]*$" ; then
      if [ $answer -le ${#VARIANTS[@]} ] ; then
        selection=${VARIANTS[$(($answer-1))]}
      else
        echo
        echo "** Invalid variant $selection"
        return
      fi
    else
      selection=$answer
    fi
  fi

  if echo $selection | grep -q _defconfig ; then
    selection=${selection::-10}
  fi

  export _BR2_CONFIG=$selection
  export BR2_OUTDIR=$BR2_OUTROOT/$_BR2_CONFIG
  export OUT=$BR2_OUTDIR
  #--------
  insert_path_f $BR2_OUTDIR/host/bin
}

function _make() {
  T=$(gettop)
  if [ ! "$T" ] ; then
    echo "Couldn't locate the project root"
  else
    export BR2_EXTERNAL=
    if [ -n "$EXTERNALS" ] ; then
      export BR2_EXTERNAL=\"${EXTERNALS:1}\"
    fi
    local start=$(date +%s)

    mkdir -p $BR2_OUTDIR
    if [ -e $BR2_TOPDIR/Makefile ] ; then
      command make $*
    else
      command make --no-print-directory -C $BR2_BUILDDIR O=$BR2_OUTDIR $*
    fi

    local ret=$?
    local end=$(date +%s)

    local diff=$(($end-$start))
    local hours=$(($diff/3600))
    local mins=$((($diff%3600)/60))
    local secs=$(($diff%60))

    echo
    if [ $ret -eq 0 ] ; then
      echo -n "#### make complete successfully "
    else
      echo -n "#### make failed to build "
    fi

    if [ $hours -gt 0 ] ; then
      printf "(%02g:%02g:%02g (hh:mm:ss))" $hours $mins $secs
    elif [ $mins -gt 0 ] ; then
      printf "(%02g:%02g (mm:ss))" $mins $secs
    elif [ $secs -gt 0 ] ; then
      printf "(%s seconds)" $secs
    fi

    echo " ####"
    return $ret
  fi
}

function make {
  _make ${_BR2_CONFIG}_defconfig 1>/dev/null
  _make $*
}

for extdir in \
    `test -d $BR2_TOPDIR/device && find -L $BR2_TOPDIR/device -maxdepth 4 -name external.desc 2>/dev/null | sort`\
    `test -d $BR2_TOPDIR/vendor && find -L $BR2_TOPDIR/vendor -maxdepth 4 -name external.desc 2>/dev/null | sort`; do
  EXTERNALS="$EXTERNALS ${extdir%/*}"
done

#--------
# source external.sh to see if add_lunch_combo is invoked,
# then build variants with _load_variants if not specified.
for extdir in $EXTERNALS ; do
  if [ -e $extdir/external.sh ] ; then
    source $extdir/external.sh
  fi
done

#--------
_load_variants $BR2_CONFIGS
for extdir in $EXTERNALS ; do
  _load_variants $extdir/configs
done

