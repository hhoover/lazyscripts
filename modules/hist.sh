#!/bin/bash
# creates a profile.d file to configure history timestamping
if [ ! -f /etc/profile.d/histformat.sh ]; then
  echo -e "# history timestamp\nexport HISTTIMEFORMAT=\"%F %T  \"" > /etc/profile.d/histformat.sh
fi

export HISTTIMEFORMAT="%F %T  "
