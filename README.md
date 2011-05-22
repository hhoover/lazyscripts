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
* David Wittman

<h3>How to use:</h3>
<p> Run this bash function as root:</p>
	function lsgethelper() { if [ -d /root/.lazyscripts ]; then cd /root/.lazyscripts/tools && git pull git://github.com/hhoover/lazyscripts.git; fi; cd ~ ; git clone git://github.com/hhoover/lazyscripts.git /root/.lazyscripts/tools; source /root/.lazyscripts/tools/ls-init.sh; }; lsgethelper && lslogin

<h3>Functions included:</h3>
* lsinfo  - Display useful system information 
* lsbwprompt  - Switch to a plain prompt. 
* lscolorprompt  - Switch to a fancy colorized prompt. 
* lsbigfiles  - List the top 50 files based on disk usage. 
* lsmytuner  - MySQL Tuner. 
* lshighio  - Reports stats on processes in an uninterruptable sleep state. 
* lsmylogin  - Auto login to MySQL 
* lsmyengines  - List MySQL tables and their storage engine. 
* lsmyusers  - List MySQL users and grants. 
* lsapcheck  - Verify apache max client settings and memory usage. 
* lsapdocs  - Prints out Apache's DocumentRoots 
* lsapproc  - Shows the memory used by each Apache process 
* lsrblcheck  - Server Email Blacklist Check 
* lsvhost  - Add an Apache virtual host 
* lspostfix  - Set up Postfix for relaying email 
* lslsync  - Install lsyncd and configure this server as a master
* lswordpress  - Install Wordpress on this server 
* lswebmin  - Install Webmin on this server 
* lsconcurchk  - Show concurrent connections 
* lswhatis  - Output the script that would be run with a specific command.

<p>Enjoy!</p>
