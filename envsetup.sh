export TOP=$PWD
export BUILDROOT=$TOP/build
export BUILDROOT_CONFIGS=$BUILDROOT/configs
export BUILDROOT_TOPDIR=$TOP
export BUILDROOT_WORKDIR=$TOP/out

#-- Environment variable for buildroot
function _supp_out() {
  if [ "$SUPPRESS_OUT" == 'y' ] ; then
    export BUILDROOT_OUTDIR=
  elif [ -z "$BUILDROOT_OUTDIR" ] ; then
    export BUILDROOT_OUTDIR=$BUILDROOT_WORKDIR
  fi
}

function hmm() {
  echo "Invoke . build/envsetup.sh to add following functions to your environment:"
  echo
  echo "croot   Change to the project root"
  echo "lunch   Set the architect to build"
  echo "make    Make the build in the correct directory"
  echo
  echo "Variable SUPPRESS_OUT=y could suppress the output directory and use the"
  echo "default path to build the toolchain."
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
    while [ ! -f THIS_FILE -a $PWD != "/" ] ; do
      cd ..
      T=`PWD= pwd -P`
    done

    cd $HERE
    if [ -f "$T/THIS_FILE" ]  ; then
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

VARIANTS=()
EXTERNALS=

function _load_variants() {
  if [ "$1" != $BUILDROOT_CONFIGS ] ; then
    EXTERNALS="$EXTERNALS,${1%/*}"
  fi

  for variant in `ls $1/*_defconfig 2>/dev/null` ; do
    VARIANTS=(${VARIANTS[@]} ${variant##*/})
  done
}

function _build_env() {
  #- find out prebuilts and add them into PATH
  if [ -e $BUILDROOT_WORKDIR/.config ] ; then
    for prebuilts in `cat $BUILDROOT_WORKDIR/.config | grep _PREBUILTS`; do
      path=`echo $prebuilts | awk -F\" ' { print $2 } '`
      if test -e $path/bin && echo $PATH | grep -qv ":$path/bin" ; then
        export PATH=$PATH:$path/bin
      elif test -e $path && echo $PATH | grep -qv ":$path" ; then
        export PATH=$PATH:$path
      fi
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
        echo "    $i. $variant"
        i=$(($i+1))
      done

      echo
      echo -n "Which variant? [${VARIANTS[0]}] "
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

  if echo $selection | grep -qP _defconfig ; then
    selection=${selection::-10}
  fi

  _supp_out

  make ${selection}_defconfig 1>/dev/null
  _build_env
}

function make() {
  T=$(gettop)
  if [ ! "$T" ] ; then
    echo "Couldn't locate the project root"
  else
    if [ -n $EXTERNALS ] ; then
      options=BR2_EXTERNAL=${EXTERNALS:1}
    fi
    local start=$(date +%s)
    mkdir -p $BUILDROOT_WORKDIR
    command make -C $BUILDROOT $options $* O=$BUILDROOT_WORKDIR BR2_TOP_DIR=$BUILDROOT_TOPDIR/ BR2_OUT_DIR=$BUILDROOT_OUTDIR/
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

#--------
_load_variants $BUILDROOT_CONFIGS
for extdir in $BUILDROOT_TOPDIR/*/*/buildroot/configs ; do
  _load_variants $extdir
done

HOST_BIN_DIR=$BUILDROOT_WORKDIR/host/bin
if echo $PATH | grep -qv $HOST_BIN_DIR ; then
  export PATH=$HOST_BIN_DIR:$PATH
fi
