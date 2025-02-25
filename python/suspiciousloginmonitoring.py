# Write script to
#
# Parse system logs for failed login attempts
# Identify repeated login failures from the same IP
# Alert the user if a threshold is exceeded
# Monitor privileged account Logins

# Then finally simulate failed logins and observe how the script detects them

# From Appendix B section in the instructions:
import re
import time
from collections import defaultdict
import subprocess
# Log file path (adjust to your system)
log_file = "/var/log/auth.log" # Example: /var/log/auth.log on Linux
# Failed login threshold
threshold = 5
time_window = 600 # 10 minutes in seconds
# Dictionary to store failed login attempts (IP: [timestamps])
failed_attempts = defaultdict(list)
def analyze_logs():
    while True:
        try:
            with open(log_file, "r") as f:
                for line in f:
                    # Regex to extract IP and login status (adapt to your log format)
                    match = re.search(r"Failed\spassword\sfor\s.*\s(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})", line, re.IGNORECASE)
                    if match:
                        ip = match.group("ip")
                        failed_attempts[ip].append(time.time())
                        # Check for threshold
                        now = time.time()
                        recent_attempts = [t for t in failed_attempts[ip] if now - t < time_window]
                        failed_attempts[ip] = recent_attempts # Keep onlyrecent attempts
                        if len(recent_attempts) >= threshold:
                            print(f"ALERT: Potential brute-force attack from IP: {ip}")
                            try:
                                print(f"WARNING: Blocking potential brute-force from IP: {ip}")
                                result = subprocess.run(["sudo", "iptables", "-A", "INPUT", "-s", ip, "-j", "DROP"], check=True, capture_output=True)
                            except subprocess.CalledProcessError as e:
                                print(f"ERROR: {e}")
                                
            time.sleep(60) # Check every minute
        except FileNotFoundError:
            print(f"Error: Log file '{log_file}' not found.")
            break
        except Exception as e:
            print(f"An error occurred: {e}")
            break
if __name__ == "__main__":
    analyze_logs()