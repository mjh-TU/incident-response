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
# Dictionary to track last time IP was alerted
last_alert_time = {}

def analyze_logs():
    last_position = 0
    
    while True:
        try:
            with open(log_file, "r") as f:
                f.seek(last_position)
                lines = f.readlines()
                last_position = f.tell()

                now = time.time()
                new_alerts = False
                
                for line in lines:
                    # Regex to extract IP from failed login attempts
                    match = re.search(r"Failed\spassword\sfor\s.*\s(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})", line, re.IGNORECASE)
                    if match:
                        ip = match.group("ip")
                        failed_attempts[ip].append(now)
                        
                        # Only recent attempts
                        failed_attempts[ip] = [t for t in failed_attempts[ip] if now - t < time_window]

                        # Threshold check
                        if len(failed_attempts[ip]) >= threshold:
                            if ip not in last_alert_time or now - last_alert_time[ip] >= time_window:
                                print(f"\033[1;31mALERT\033[0m: Potential brute-force attack from IP: {ip}")
                                try:
                                    print(f"WARNING: Blocking potential brute-force from IP: {ip}")
                                    result = subprocess.run(["sudo", "iptables", "-A", "INPUT", "-s", ip, "-j", "DROP"], check=True, capture_output=True)
                                    print(f"WARNING: Blocked IP {ip}")
                                except subprocess.CalledProcessError as e:
                                    print(f"ERROR: {e}")

                                last_alert_time[ip] = now
                                new_alerts = True
                                
            if not new_alerts:
                print(f"INFO: No new alerts or warnings as of {time.strftime('%Y-%m-%d %H:%M:%S')}")
            time.sleep(60) # Check every minute
            
        except FileNotFoundError:
            print(f"Error: Log file '{log_file}' not found.")
            break
        except Exception as e:
            print(f"An error occurred: {e}")
            break
if __name__ == "__main__":
    analyze_logs()
