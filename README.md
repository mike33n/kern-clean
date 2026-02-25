Kernel Cleaner Script for Debian/Ubuntu/Mint

This script is a powerful tool for maintaining order on Debian/Ubuntu-based systems. Its primary purpose is to safely remove old Linux Kernel versions and related packages to reclaim significant disk space.
Features

<b>1. System Detection</b>
The script starts by detecting whether you are running on a physical machine or a virtual one. This helps you identify if you are managing real hardware or a cloud instance.

<b>2. Kernel Package Management (Options 1-4)</b>
These options allow you to selectively remove Kernel Images, Headers, and Modules. The script automatically prevents the removal of the currently running kernel (ACTIVE) to ensure system stability.

<b>3. Autoremove (Option "a")</b>
Executes the apt autoremove --purge command. It cleans the system of packages that were installed as dependencies but are no longer required by any other software.

<b>4. Cleaning Ghost Packages (Option "c")</b>
Removes packages with rc status (residual config). These are remnants of uninstalled programs that still keep configuration files in the system.

<b>5. Removing Dead Modules (Option "f")</b>
Scans the /lib/modules directory and deletes folders that do not belong to any installed kernel. After updates, "orphaned" files often remain there, consuming hundreds of megabytes.

<b>6. Safety and GRUB Update</b>
Whenever a kernel is removed, the script automatically runs update-grub. This ensures the system's bootloader menu is always up-to-date and does not contain links to non-existent versions.
Installation & Quick Access

If you want to run this script from anywhere in your terminal by simply typing kern-clean, follow these steps:

    Move the script to the binary directory:
    Bash

    sudo cp your_script_name.sh /usr/local/bin/kern-clean

    Set execution permissions:
    Bash

    sudo chmod +x /usr/local/bin/kern-clean

    Usage:
    Now, you can run the tool anytime by typing:
    Bash

    kern-clean

Requirements

    OS: Debian, Ubuntu, or Linux Mint.

    Privileges: Root/Sudo access is required to remove packages.

    Dependencies: bc (The script will check for this automatically).
