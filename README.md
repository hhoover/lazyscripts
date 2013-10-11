# LazyScripts

This is a set of bash shell functions to simplify and automate specific routine tasks, as well as some more specialized ones.

## Compatibility
* RedHat Enterprise Linux 5+
* CentOS 5+
* Ubuntu 10.04+

## Installation
Run this bash function as root:

```bash
function lsgethelper() {
        local LZDIR=/root/.lazyscripts/tools;
        if command -v git 2>&1 1>/dev/null; then
            if [[ -d ${LZDIR} ]]; then
                    cd "${LZDIR}" \
                    && git reset --hard HEAD \
                    && git clean -f	\
                    && git pull git://github.com/hhoover/lazyscripts.git master; \
            else
                    cd \
                    && git clone git://github.com/hhoover/lazyscripts.git "${LZDIR}";
            fi
            cd;
            source ${LZDIR}/ls-init.sh;
        else
            rm -rf "${LZDIR}"/lazyscripts-master
            cd "${LZDIR}" \
            && curl -L https://github.com/hhover/lazyscripts/archive/master.tar.gz | tar xvz
            cd;
            source "${LZDIR}"/lazyscripts-master/ls-init.sh;
        fi
}
lsgethelper && lslogin
```
Throw this in your .bashrc for extra credit.
## Functions
| **Function** | **Description** |
|:-------------|:----------------|
|lsinfo|Display useful system information|
|lsbwprompt|Switch to a plain prompt.|
|lscolorprompt|Switch to a fancy colorized prompt.|
|lsbigfiles|List the top 50 files based on disk usage.|
|lsmytuner|MySQL Tuner.|
|lshighio|Reports stats on processes in an uninterruptable sleep state.|
|lsmylogin|Auto login to MySQL|
|lsmyengines|List MySQL tables and their storage engine.|
|lsmyusers|List MySQL users and grants.|
|lsmycreate|Creates a MySQL DB and MySQL user|
|lsmycopy|Copies an existing database to a new database.|
|lsap|Show a virtual host listing.|
|lsapcheck|Verify apache max client settings and memory usage.|
|lsapdocs|Prints out Apache's DocumentRoots|
|lsapproc|Shows the memory used by each Apache process|
|lsrblcheck|Server Email Blacklist Check|
|lscloudkick|Installs the Cloudkick agent|
|lsvhost|Add an Apache virtual host|
|lsvsftpd|Installs/configures vsftpd|
|lspostfix|Set up Postfix for relaying email|
|lsparsar|Pretty sar output|
|lslsync|Install lsyncd and configure this server as a master|
|lswordpress|Install Wordpress on this server|
|lsdrupal|Install Drupal 7 on this server|
|lswebmin|Install Webmin on this server|
|lsvarnish|Installs Varnish 3.0|
|lsconcurchk |Show concurrent connections|
|lscrtchk|Check SSL Cert/Key to make sure they match|
|lsrpaf|Install mod_rpaf to set correct client IP behind a proxy.|
|lspma|Installs phpMyAdmin|
|lsnginx|Replace Apache with nginx/php-fpm|
|lshaproxy|Install HAProxy on this server|
|lshppool|Adds a new pool to an existing HAProxy config|
|lswhatis|Output the script that would be run with a specific command.|
|lsnodejs|Installs Node.js and Node Package Manager|
|lsapitools|Installs API tools for Rackspace Cloud|
|lsrecap|Installs Recap - https://github.com/rackerlabs/recap|
|lsnova|Nova Configuration generator|

Enjoy!
