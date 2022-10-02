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
		RESULT=$(gpg --verify hashes.txt 2>&1)
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
				echo -e "FILE $1  IS $(tput bold)$(tput setab 82)$(tput setaf 16) FINE ! $(tput sgr0)\n"
				echo "SHA256 is OK:"
				echo "$sha256_hash  is hash from hashes.txt"
				echo "$real_sha_hash  is hash of $1 \n"
				# TODO: ask for UNTAR
				echo "Decompressing.."
				tar xvf $1
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

# ./monero-check-download.sh: line 40: shasum: command not found
# FILE monero-linux-armv7-v0.10.2.1.tar.bz2  IS  FINE !
# SHA256 is OK:
# ad6bccc0b738e5becc0191fea2c55529835df042919ef8df60033f8e84c28a9d  is hash from hashes.txt
# ad6bccc0b738e5becc0191fea2c55529835df042919ef8df60033f8e84c28a9d  is hash of monero-linux-armv7-v0.10.2.1.tar.bz2
# android@localhost:~$ (shasum -a 256 monero-linux-armv7-v0.10.2.1.tar.bz2 || sha256sum monero-linux-armv7-v0.10.2.1.tar.bz2) | cut -d' ' -f1
# -bash: shasum: command not found
# ad6bccc0b738e5becc0191fea2c55529835df042919ef8df60033f8e84c28a9d

# TODO 2: use functions
# TODO 3: more colors: eg: <green>[i]</green> hashes.txt from https://getmonero.org/downloads/hashes.txt downloaded. 