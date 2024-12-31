# oshealthcheck: Linux utility to check system information

### Author: Tin Trung Ngo
### Contact: trungtinth1011@gmail.com

## Before you begin

This script is used to create a report in Linux/Unix system information.

** Note: You need to be the **super user** or in **sudo group** before running the script

> This script has been tested and works well on Debian 11, CentOS 7, Ubuntu 20.04, Red Hat 8.2

The script is written with the aim to check some system information of Linux/Unix servers. What is does include:
1. OS services: Collect host information

## Setup

To turn `oshealthcheck` function into an executable command, run below command:

```bash
cat <<'EOF' >> $HOME/.zshrc OR cat <<'EOF' >> $HOME/.bashrc

function oshealthcheck() {
  . $HOME/path/to/main.sh
}
EOF
```

## License

[Apache License 2.0](/LICENSE)
