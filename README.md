# spf-parser
Dependencies: dig
For Debian-based distro, install it by `apt-get install bind9-dnsutils`. For RedHat-based ones, you can install it through the command `dnf install bind-utils`

Bash script that automates the parsing of SPF record by recursively iterating through all the mechanisms:

* include
* a
* ptr
* mx
* ip4
* redirect
