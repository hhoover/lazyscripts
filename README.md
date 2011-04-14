<h1>LazyScripts</h1>

<p>This is a set of bash shell functions to simplify and automate specific routine tasks, as well as some more specialized ones.</p>

<p>Compatibility - RHEL 5, CentOS 5, Ubuntu 10.04, Ubuntu 10.10</p>

<h3>Contributors:</h3>
* Hart Hoover
* Tim Galyean
* Kale Stedman
* Trey Feagle
* Jason Dunsmore
* Jacob Walcik
* Farid Saad

<h3>How to use:</h3>

	git clone https://hhoover@github.com/hhoover/lazyscripts. /root/.lazyscripts/tools
	cd /root/.lazyscripts/tools
	source ls-init.sh && lslogin

<p>You can also use this bash function upon login as root:</p>

	function lsgethelper() { LZS_PREFIX="/root/.lazyscripts/tools"; LZS_URLPREFIX="https://hhoover@github.com/hhoover/lazyscripts.git"; LZS_APP="$LZS_PREFIX/ls-init.sh"; if [ -e $LZS_APP ]; then rm -rf $LZS_PREFIX; fi; echo "Installing LazyScripts..."; cd ~ ; git clone $LZS_URLPREFIX $LZS_PREFIX > /dev/null 2>&1 ; source $LZS_APP; } lsgethelper && lslogin

<p>Enjoy!</p>