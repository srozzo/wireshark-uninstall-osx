# Wireshark OS X Uninstall Tool


The missing OS X uninstall script for Wireshark

---
## Overview

This script that attempts to intelligently uninstall Wireshark based on the rough guidance provided in the "Read me first.rtf" along with the OS X installer

** From "Read me first.rtf" **

 How do I uninstall?

    1. Remove /Applications/Wireshark
    2. Remove the wrapper scripts from /usr/local/bin
    3. Remove /Library/StartupItems/ChmodBPF
    4. Remove the access_bpf group.

---

## Instructions

\# sudo bash -c "$(curl -sL https://raw.github.com/srozzo/wireshark-uninstall-osx/master/uninstall.sh)"

** Alternatively **

Download the script, ensure it is executable (chmod u+x) and run it as root.

---

## License

GNU General Public License version 2 
(For compatibility with Wiresharks licensing) 
