# oshealthcheck

**Author**: Tin Trung Ngo

**Contact**: trungtinth1011@gmail.com

Linux utility to check system information

<br>

## Before you begin

The script is written with the aim to check some system information of Linux/Unix servers. What is does include:
1. Collect host information


** Note: You need to be the **super user** or in **sudo group** before running the script.

This script has been tested and works well on
> amd64: Amazon Linux 2023

> arm64: MacOS

<br>

## Setup

To turn `oshealthcheck` function into an executable command, run below command:

```bash
cat <<'EOF' >> $HOME/.zshrc OR cat <<'EOF' >> $HOME/.bashrc

function oshealthcheck() {
  . $HOME/path/to/main.sh
}
EOF
```

<br>

## License

[Apache License 2.0](/LICENSE)
