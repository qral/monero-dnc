#!/usr/bin/env bash

# this will check gpg signed hashes from getmonero.org 

# https://web.getmonero.org/resources/user-guides/verification-allos-advanced.html#32-verify-hash-file

# vars
basename_file=`basename "$1"`
hashes_url='https://getmonero.org/downloads/hashes.txt'

# signature can be made by other ppl then fluffypony
# https://github.com/monero-project/monero/tree/master/utils/gpg_keys/
# fluffy wants to step down from King of monero devs so binaryfate is it now
# leaving variable names with fluffy as a memory :)
#gpg_fluffy_url='https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/fluffypony.asc'
gpg_fluffy_url='https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc'

#fluffypony.asc
gpg_fluffy_filename=${gpg_fluffy_url##*/}

# -s -S -O (save as remote filename) -L (follow redirects)
curl='curl --silent --show-error --remote-name --location'
if ! command -v curl &> /dev/null
then
	curl='wget '
	command -v wget >/dev/null 2>&1 || { echo >&2 "wget/curl is required but it's not installed.  Aborting."; exit 1; }
fi
command -v shasum >/dev/null 2>&1 || { echo >&2 "shasum is required but it's not installed.  Aborting."; exit 1; }
# for unzip it should be bunzip2, bzip2 -d works also
command -v bunzip2 >/dev/null 2>&1 || { echo >&2 "BZIP2 is required but it's not installed.  Aborting."; exit 1; }
command -v gpg >/dev/null 2>&1 || { echo >&2 "GPG is required but it's not installed.  Aborting."; exit 1; }

# cleanup from last run
rm hashes.txt wget.log 2>/dev/null

# check if the filename is provided
if [[ -n "$1" ]]; then
 	#echo "ist param is: $1"
 	echo "Downloading hashes.txt"
 	`$curl $hashes_url`
 	if [[ "$?" -eq 0 ]]; then
		echo "hashes.txt from $hashes_url downloaded."
		gpg --list-keys | grep "binaryfate@getmonero.org"
		if [[ "$?" -eq 0 ]]; then
			echo "GPG keys are already imported."
		else
			echo "Downloading Binaryfate's GPG key.."
			`$curl $gpg_fluffy_url`
			if [[ "$?" -eq 0 ]]; then
				echo -e "Importing Binaryfate's GPG key..\n"
				# TODO!
				# here should be some fingerprint matching...
				# pub   rsa4096/F0AF4D462A0BDF92 2019-12-12 [SCEA]
				# Key fingerprint = 81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92
				# uid                           binaryFate <binaryfate@getmonero.org>
				`gpg --import $gpg_fluffy_filename`
				if [[ "$?" -eq 0 ]]; then
					echo "Binaryfate's GPG key was imported."
				else echo "GPG problem"; exit 1; fi
			fi
 		fi
		# gpg prints to STDERR hence the redirection
		echo -e "\n Verifying hashes.txt... \n"
		# LC_ALL=C or LANG=C because I need ENGLISH output, not localised
		RESULT=$(LC_ALL=C gpg --verify hashes.txt 2>&1)
		if [[ "$RESULT" =~ "Good signature from" ]]; then
			#`grep  "$1" hashes.txt | cut -d" " -f1`
			# sha256_hash=$(grep "$basename_file" hashes.txt)
			# ->
			# + sha256_hash='a13299bcf11cdcaeafa0c19ef410cb27020def501345ab03a939ddcfb8a20de7  monero-mac-x64-v0.10.2.1.tar.bz2'
			# monero-mac-x64-v0.15.0.1.tar.bz2, f3648a94fc9252a2e5b6e56978e756ff272403ec385f8be42338cae3f4f4e8a5 they changed it again
			# May 2020: 6cae57cdfc89d85c612980c6a71a0483bbfc1b0f56bbb30e87e933e7ba6fc7e7  monero-linux-x64-v0.15.0.5.tar.bz2
			sha256_hash=$(awk -v filename="$basename_file" '$0 ~ filename {print $1}' hashes.txt)
			# shasum is on Mac, sha256sum on CentOS
			real_sha_hash=$( (shasum -a 256 "$1" || sha256sum "$1") | cut -d' ' -f1)
			if [[ $sha256_hash == $real_sha_hash ]]; then
				echo
				echo -e "FILE  $1  IS $(tput bold)$(tput setab 82)$(tput setaf 16) FINE ! $(tput sgr0)"
				echo
				echo "SHA256 is OK:"
				echo "$sha256_hash  is hash from hashes.txt"
				echo "$real_sha_hash  is hash of $1"
				echo
				# EXTRACTING, ask user
				# [-n nchars] [-p prompt]
				#  -r	do not allow backslashes to escape any characters
				# http://linuxcommand.org/lc3_man_pages/readh.html 
				# https://ss64.com/bash/read.html
				read -p "Extract the downloaded file? [Y/y/n]: " -n 1 -r
				# if REPLY is unset or null (it is after pressing ENTER), then replace it with 'Y'
				REPLY=${REPLY:-Y}
				echo
				if [[ $REPLY =~ ^[Yy]$ ]]
				then
				  echo "[i] Extracting file.."
				  tar xvf $1
				  # delete the archive?
				  if [[ "$?" -eq 0 ]]
				  then
				    echo
				  	echo "[i] lets delete the downloaded archive, confirm with [yY]"
				    rm -iv $1
				  fi
				else
				  echo "Exiting..bye"
				  exit
				fi
				# need to know/find real file/DIRname AFTER untar
				# monero-linux-x64-v0.18.3.2.tar.bz2 is decompressed to -> monero-x86_64-linux-gnu-v0.18.3.2
				# that +1 step
				# if [[ -d "$1" ]]; then
				# 	echo "File was already decompressed.."
				# else
				# 	echo "Decompressing.."
				# 	tar xvf $1
				# fi
			else
				echo "$(tput bold)$(tput setab 1) VERIFICATION FAILED! DO NOT CONTINUE! $(tput sgr0)"
			fi
		else
			echo "Verification failed..do not continue."
		fi
 	fi
else
	echo "Usage: $0 <filename.tar.bz2>"
fi 


# TODO 1: check for available commands (curl/wget, shasum etc) and then use the available command per platform
# example what happened when run on debian armv7 linux-deploy (htc desire z):


# TODO 2: use functions
# TODO 3: more colors: eg: <green>[i]</green> hashes.txt from https://getmonero.org/downloads/hashes.txt downloaded. 
# TODO 4: replace TPUT with escapes seq (got "tput: unknown terminal "xterm-kitty"  or tput: command not found)
#         https://github.com/ryukinix/dotfiles/issues/5 
#         tput needs ncurses-utils pkg
# TODO 5: ask for decompression or check if it is already decompressed...
# TODO 6: sh compatible? remove [[]] and use single []?
# TODO 7: better HASH check? 
# 
# $ shasum -a 256 monero-linux-x64-v0.18.3.2.tar.bz2 | shasum -a 256 -c
# monero-linux-x64-v0.18.3.2.tar.bz2: OK
# $ echo $?
# 0
# 
# TODO 8: on android termux is only GPGV which needs keyring with keys
