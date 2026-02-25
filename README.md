<b>1. Wykrywanie Środowiska (System Detection)</b>
---------------

<b>PL:</b> Skrypt na wstępie sprawdza, czy pracujesz na maszynie fizycznej, czy wirtualnej (Virtualization detection). Dzięki temu wiesz, czy zarządzasz realnym sprzętem, czy np. kontenerem w chmurze.

<b>EN:</b> The script starts by detecting whether you are running on a physical machine or a virtual one. This helps you identify if you are managing real hardware or a cloud instance.

<b>2. Opcje 1-4: Zarządzanie Pakietami Jądra (Kernel Package Management)</b>
---------------

<b>PL:</b> Pozwalają na selektywne usuwanie obrazów jądra (Images), nagłówków (Headers) oraz modułów (Extra/Base). Skrypt automatycznie blokuje możliwość usunięcia aktualnie używanego jądra (ACTIVE), co zapobiega uszkodzeniu systemu.

<b>EN:</b> These options allow you to selectively remove Kernel Images, Headers, and Modules. The script automatically prevents the removal of the currently running kernel (ACTIVE) to ensure system stability.

<b>3. Opcja "a": Autoremove</b>
---------------

<b>PL:</b> Wykonuje komendę apt autoremove --purge. Czyści system z pakietów, które zostały zainstalowane jako zależności, ale nie są już wymagane przez żaden inny program.

<b>EN:</b> Executes the apt autoremove --purge command. It cleans the system of packages that were installed as dependencies but are no longer required by any other software.

<b>4. Opcja "c": Czyszczenie "Duchów" (Cleaning Ghost Packages)</b>
---------------

<b>PL:</b> Usuwa pakiety o statusie rc (residual config). Są to pozostałości po odinstalowanych programach, które wciąż przechowują pliki konfiguracyjne w systemie.

<b>EN:</b> Removes packages with rc status (residual config). These are remnants of uninstalled programs that still keep configuration files in the system.

<b>5. Opcja "f": Usuwanie Martwych Folderów (Removing Dead Modules)</b>
---------------

<b>PL:</b> Skanuje katalog /lib/modules i usuwa foldery, które nie należą do żadnego zainstalowanego jądra. Często po aktualizacji zostają tam "osierocone" pliki zajmujące setki megabajtów.

<b>EN:</b> Scans the /lib/modules directory and deletes folders that do not belong to any installed kernel. After updates, "orphaned" files often remain there, consuming hundreds of megabytes.

<b>6. Bezpieczeństwo i Aktualizacja GRUB (Safety and GRUB Update)</b>
---------------

<b>PL:</b> Przy każdym usunięciu jądra, skrypt automatycznie wykonuje update-grub. Dzięki temu menu startowe systemu (bootloader) jest zawsze aktualne i nie zawiera odnośników do nieistniejących wersji.

<b>EN:</b> Whenever a kernel is removed, the script automatically runs update-grub. This ensures the system's bootloader menu is always up-to-date and does not contain links to non-existent versions

***********
<b>INSTALACJA / Installation"</b>
---------------
PL: Jeśli chcesz uruchamiać ten skrypt z dowolnego miejsca, wpisując po prostu kern-clean

EN: If you want to run this script from anywhere by simply typing kern-clean

    sudo cp your_script.sh /usr/local/bin/kern-clean

    sudo chmod +x /usr/local/bin/kern-clean
