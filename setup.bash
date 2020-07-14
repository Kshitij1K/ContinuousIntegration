CURRDIR=$(dirname "$0")

cp $CURRDIR/test.bash $CURRDIR/.git/hooks/commit-msg
cp $CURRDIR/check_version.py $CURRDIR/.git/hooks/check_version.py

sudo chmod +x $CURRDIR/.git/hooks/commit-msg $CURRDIR/.git/hooks/check_version.py