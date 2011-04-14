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
	function lsgethelper() { cd ~ ; git clone git://github.com/hhoover/lazyscripts.git /root/.lazyscripts/tools; source /root/.lazyscripts/tools/ls-init.sh; }; lsgethelper && lslogin
<p>Enjoy!</p>
