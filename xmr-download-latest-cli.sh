# cat xmr-download-latest-cli.sh
# stahne to spravne pojmenovany.. jeste by melo existovat --content-disposition
# redirection needed so we can catch the output.. tee will save out to file 'name'
# -nv
#wget --no-verbose --trust-server-names https://downloads.getmonero.org/cli/linux64 2>&1 | tee name
#wget --trust-server-names https://downloads.getmonero.org/cli/linux64 2>&1 | tee name


# TODO: it could run ./monerod --version to check actual version first


# mac/linux?
# TODO: WIN
# use CASE ?
system=`uname`
if [[ "$system" == "Darwin" ]]; then
  system_uri="https://downloads.getmonero.org/cli/mac64"
  grep_name="monero-mac-x64.*bz2$"
elif [[ "$system" == "Linux" ]]; then
  system_uri="https://downloads.getmonero.org/cli/linux64"
  grep_name="monero-linux-x64.*bz2$" 
else
  echo "unsupported OS"
  exit
fi

echo "downloading binary $grep_name for $system_uri .. you can check wget.log"
wget --trust-server-names $system_uri -o wget.log
# alternative: curl --remote-header-name --remote-name

# -o outputs only matched pattern
fname=`grep -o $grep_name wget.log`
echo $fname
./xmr-check-download.sh $fname
