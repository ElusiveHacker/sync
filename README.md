# sync.sh - Active Directory Clock Synchronization Script

## Description
`sync.sh` is a Bash script designed to synchronize the system clock with an Active Directory domain controller using NTP (Network Time Protocol). It checks for root privileges, validates the target IP, verifies connectivity, and attempts to sync time using `ntpdate`. The script also supports a quiet mode and generates logs and reports for each run.

## Features
- Root user verification
- IPv4 address validation
- Ping test to check host connectivity
- NTP port (UDP 123) availability check
- Multiple sync attempts with detailed logging
- Quiet mode to suppress output
- Detailed log and report files generated in the script directory
- Help message for usage instructions

## Requirements
- Bash shell (tested with GNU Bash 5.2+)
- `ntpdate` command line tool
- `netcat` (`nc`) utility
- `sudo` configured for running `ntpdate` if not root

## Usage

```bash
sudo ./sync.sh -i <IP_ADDRESS> [--quiet] [--help]
```

### Arguments:
- `-i <IP_ADDRESS>` : Specify the IPv4 address of the Active Directory domain controller to sync with.
- `--quiet`         : Run the script in quiet mode (minimal output).
- `--help`          : Display the help message.

### Example:
```bash
sudo ./sync.sh -i 192.168.1.10
sudo ./sync.sh -i 192.168.1.10 --quiet
```

## Output
- Log file: `sync.log` (in script directory)
- Report file: `<YYYYMMDD_HHMM>_sync.txt` (timestamped file in script directory)

## Notes
- The script must be run with root privileges or via `sudo`.
- Ensure that NTP port UDP/123 is open and reachable on the target IP.
- `sudo` may be required if not running as root to execute `ntpdate`.

## License
MIT License

## Author
Created by ChatGPT
