# (6) Install instructions for OpenFst

# Note that this should be compiled with g++-4.x
# You may have to install this and give the option CXX=<g++-4-binary-name>
# to configure, if it's not already the default (g++ -v will tell you).
# (on cygwin you may have to install the g++-4.0 package and give the options CXX=g++-4.exe CC=gcc-4.exe to configure).

(
  echo "****(6) Install openfst"

  rm openfst-1.3.2.tar.gz 2>/dev/null
  wget http://openfst.cs.nyu.edu/twiki/pub/FST/FstDownload/openfst-1.3.2.tar.gz || \
   wget --no-check-certificate -T 10 -t 3 https://sourceforge.net/projects/kaldi/files/openfst-1.3.2.tar.gz

  if [ ! -e openfst-1.3.2.tar.gz ]; then
    echo "****download openfst-1.3.2.tar.gz failed."
    exit 1
  else
    tar -xovzf openfst-1.3.2.tar.gz   || exit 1
    ( cd openfst-1.3.2/src/include/fst && patch -p0 -N <../../../../openfst.patch )
    #ignore errors in the following; it's for robustness in case
    # someone follows these instructions after the installation of openfst.
    ( cd openfst-1.3.2/include/fst && patch -p0 -N < ../../../openfst.patch )
    # Remove any existing link
    rm openfst 2>/dev/null
    ln -s openfst-1.3.2 openfst
     
    cd openfst-1.3.2
    # Choose the correct configure statement:

    # Linux or Darwin:
    if [ "`uname`" == "Linux"  ] || [ "`uname`" == "Darwin"  ]; then
        ./configure --prefix=`pwd` --enable-static --disable-shared --enable-far --enable-ngram-fsts || exit 1
    elif [ "`uname -o`" == "Cygwin"  ]; then
        which gcc-4.exe || exit 1
        ./configure --prefix=`pwd` CXX=g++-4.exe CC=gcc-4.exe --enable-static \
                --disable-shared --enable-far --enable-ngram-fsts || exit 1
    else
        echo "Platform detection error"
        exit 1
    fi

    # make install is equivalent to "make; make install"
    make install || exit 1
    cd ..
  fi
)
ok_openfst=$?
if [ $ok_openfst -ne 0 ]; then
  echo "****Installation of OpenFst failed"
fi

