<h1>LazyScripts</h1>

<p>This is a set of bash shell functions to simplify and automate specific routine tasks, as well as some more specialized ones.</p>

<p>Compatibility - RHEL/CentOS 5+, Ubuntu 10.04+</p>

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
* lsmycreate - Creates a MySQL DB and MySQL user
* lsmycopy - Copies an existing database to a new database.
* lsapcheck  - Verify apache max client settings and memory usage. 
* lsapdocs  - Prints out Apache's DocumentRoots 
* lsapproc  - Shows the memory used by each Apache process 
* lsrblcheck  - Server Email Blacklist Check 
* lscloudkick - Installs the Cloudkick agent
* lsvhost  - Add an Apache virtual host 
* lsvsftpd - Installs/configures vsftpd
* lspostfix  - Set up Postfix for relaying email
* lsparsar - Pretty sar output
* lslsync  - Install lsyncd and configure this server as a master
* lswordpress  - Install Wordpress on this server 
* lsdrupal  - Install Drupal 7 on this server 
* lssuphp - Converts a server from mod_php to suPHP
* lswebmin  - Install Webmin on this server 
* lsvarnish - Installs Varnish 3.0
* lsconcurchk  - Show concurrent connections 
* lscrtchk - Check SSL Cert/Key to make sure they match
* lsrpaf - Install mod_rpaf to set correct client IP behind a proxy.
* lspma - Installs phpMyAdmin
* lswhatis  - Output the script that would be run with a specific command.
* lsnodejs - Installs Node.js and Node Package Manager

<p>Enjoy!</p>
