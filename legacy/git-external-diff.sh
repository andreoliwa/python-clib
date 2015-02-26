#!/bin/bash
V_TEMP_FILE=$2
V_LOCAL_FILE=$5

if [ -n "$G_SINGLE_MELD_WINDOW" ] ; then
    # Cria diretório temporário para copias de arquivo
    V_TEMP_DIR=/tmp/git-meld/
    mkdir -p $V_TEMP_DIR

    V_COPIED_FILE=$(echo $V_TEMP_FILE | sed 's#/tmp/#'$V_TEMP_DIR'#')
    cp -u $V_TEMP_FILE $V_COPIED_FILE

    #echo "Comparando $V_LOCAL_FILE com o SVN"
    echo '--diff '"$V_COPIED_FILE"' '"$V_LOCAL_FILE"
else
    if [[ "${OSTYPE//[0-9.]/}" == 'darwin' ]]; then
        github .
    else
        meld $V_TEMP_FILE $V_LOCAL_FILE # > /dev/null 2>&1
    fi
fi

# http://mycodesnippets.com/2011/06/04/git-with-meld-diff-viewer-on-ubunt/
# http://nathanhoad.net/how-to-meld-for-git-diffs-in-ubuntu-hardy
# then run this ONCE to configure this file in your local git:
# git config --global diff.external $HOME/bin/git-external-diff.sh
