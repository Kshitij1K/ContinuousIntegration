CURRDIR=$(dirname "$0")

ln -s $CURRDIR/test.bash $CURRDIR/.git/hooks/commit-msg
ln -s $CURRDIR/check_version.py $CURRDIR/.git/hooks/check_version.py
