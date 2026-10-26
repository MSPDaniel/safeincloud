## GitHub/GHCR and Unraid deployment

See [GITHUB-UNRAID-SETUP.md](GITHUB-UNRAID-SETUP.md) for the prebuilt image workflow and XML template.

---

# SafeInCloud — standalone Docker build package for Unraid

Contains a complete Docker build context (Dockerfile, Compose file, desktop launcher, application synchronization and Wine initialization scripts). **No rebuild script, confirmation prompt, or automated stop script is included.**

## Prerequisites
- Unraid with Docker Compose and internet access to build the image.
- The **complete SafeInCloud Windows portable application**, including `SafeInCloud.exe`, must be supplied separately. It is proprietary and is not included.
- Existing `/mnt/cache/appdata/safeincloud/config/` contains persistent Wine prefix, application files and vault data. **Do not delete it.**
- Port 3010 must be available. This package does not use port 3009.

## Install or replace build files
1. Back up `/mnt/cache/appdata/safeincloud/config/` and your existing `/mnt/cache/appdata/safeincloud/build/` before making changes.
2. Extract the files in this archive **directly into** `/mnt/cache/appdata/safeincloud/build/` (so `compose.yaml` and `Dockerfile` are at that level). Existing files with the same names will be replaced; `.env` should be retained.
3. Put the full portable SafeInCloud application into `/mnt/cache/appdata/safeincloud/source/` (including `SafeInCloud.exe`). For existing installations, retain your current source files unless intentionally upgrading.
4. If this is a new install, copy `.env.example` to `.env` and set a strong `WEBTOP_USER` and `WEBTOP_PASSWORD`. For existing installations, keep your existing `.env`.
5. From `/mnt/cache/appdata/safeincloud/build/`, check `docker compose config --quiet`.
6. To build and deploy, run **manually**:

   ```bash
   cd /mnt/cache/appdata/safeincloud/build
   docker compose up -d --build
   ```

   This command **may stop/recreate the currently running container**. Your host previously froze twice during container stops; ensure remote syslog and a backup are in place before using it. The package contains no automated shutdown or rebuild script.
7. Access `https://UNRAID-IP:3010` and verify your existing vault.

## Protect SafeInCloud settings and database during updates
- **`/config/safeincloud/app/Data` is preserved** when a newer application is copied from `/opt/safeincloud/source`. Before replacing the application, the update script copies the entire existing `Data` directory (including hidden files and subdirectories) into the new application staging directory. A `Data` directory shipped with the new portable app is replaced by the existing user data.
- On Unraid, this corresponds to `/mnt/cache/appdata/safeincloud/config/safeincloud/app/Data` (also accessible through `/mnt/user/appdata/safeincloud/config/safeincloud/app/Data` on your cache-only share).
- The old application directory, including its original `Data`, remains in `/config/safeincloud/app-backups/` after a successful update.
- If a previous update **already removed** your database, this package cannot recreate it. Before running another update, restore `Data` from a known-good `app-backups/app-*/Data` or another backup. **Do not rely on a newly created empty `Data` directory.**
- This preserves `Data` during future application upgrades; it is not a replacement for independent backups of your password vault.

## WPF graphics compatibility fix
- Sets `HKCU\Software\Microsoft\Avalon.Graphics` `DisableHWAcceleration` to `1` during first-time Wine initialization.
- Reapplies the same registry setting at application launch, including on existing persistent Wine prefixes. This addresses the observed Wine/X11 `BadMatch (X_CopyArea)` application exit.
- No Wine prefix reset or vault deletion is needed. A new image build is needed to incorporate the updated launch script, but the currently running container can continue using its already-fixed registry setting until you choose to rebuild.

## XFCE compositor fix (black or partially rendered windows)
- The launcher now runs `configure-xfce.sh` **before** Wine starts and sets XFCE's `xfwm4` `/general/use_compositing` property to `false` using `xfconf-query`.
- This setting is saved in the persistent `/config` XFCE profile and reapplied on each SafeInCloud launch. It fixes the observed black/unpainted window regions that previously disappeared only after dragging the window.
- This is separate from the WPF software-rendering registry fix; **both fixes are included**.
- Verify from Unraid after starting Webtop: `docker exec -u abc -e DISPLAY=:1 safeincloud xfconf-query -c xfwm4 -p /general/use_compositing` (expected `false`).

## Features and notes
- Uses LinuxServer Webtop Ubuntu XFCE, Wine, and .NET 4.8 initialization (first install can be slow and is not guaranteed on every Wine version).
- Direct ZFS bind mounts at `/mnt/cache/appdata/safeincloud/config` and `/mnt/cache/appdata/safeincloud/source`.
- 60-second graceful stop period; container `restart: unless-stopped`.
- Preserves the `/config` Wine prefix and vault data between container recreations.
- Automatically checks portable app files, preserves the existing `app/Data` directory across updates, and keeps application backups in `/config/safeincloud/app-backups/`. See scripts/sync-app.sh.
- This is a full **build package**, but not a redistributable copy of SafeInCloud itself.
- Avoid publishing port 3010 directly to the internet; use LAN/VPN or an authenticated reverse proxy.

## Troubleshooting
```bash
docker logs --tail 100 safeincloud
cat /mnt/cache/appdata/safeincloud/config/safeincloud/install.log
```

## XFCE startup synchronization (new)

The XFCE autostart launcher runs `configure-xfce.sh` **on every desktop session**, including after a Docker container restart. It waits up to 60 seconds for both `xfwm4` and `xfconfd` to run as the desktop user and for the xfconf property to become readable. It then sets `/general/use_compositing=false` using `xfconf-query` (stored persistently in the user's XFCE configuration), verifies the value, waits another 2 seconds, and verifies it again before starting Wine/SafeInCloud.

Startup diagnostics and failures are appended to `/config/safeincloud/xfce-startup.log` (host: `/mnt/cache/appdata/safeincloud/config/safeincloud/xfce-startup.log`). If the setting cannot be confirmed, the application launcher exits instead of silently starting with an unsafe rendering configuration; the Webtop container itself can remain running.

After a restart, verify with `docker exec -u abc -e DISPLAY=:1 safeincloud xfconf-query -c xfwm4 -p /general/use_compositing` (expected: `false`) and inspect the startup log. This changes only the SafeInCloud container at port 3010; existing application `Data`, Wine prefix, `.env`, and source directory must be retained.

## Delayed autostart (5 seconds after XFCE readiness)

XFCE autostart now runs `/opt/safeincloud/delayed-autostart.sh` rather than launching the application directly. The wrapper waits for `xfwm4` and `xfconfd`, verifies XFCE compositing is disabled, waits **5 seconds**, rechecks compositor state, then invokes the normal SafeInCloud launcher. The normal launcher still verifies the XFCE setting and WPF software rendering.

The **desktop shortcut is unchanged** and launches SafeInCloud immediately when clicked. The delay only applies to automatic startup after the XFCE session begins. This is an experimental mitigation for black rendering patches on initial autostart, not yet verified on the user's host.

Startup logs: `/config/safeincloud/xfce-autostart.log` and `/config/safeincloud/xfce-startup.log`. After deployment, check them with:

```bash
docker exec safeincloud tail -50 /config/safeincloud/xfce-autostart.log
```

Do not keep an old per-user autostart entry pointing directly to `launch.sh`; it can bypass the delay. If `/config/.config/autostart/safeincloud.desktop` exists, update its `Exec` to `/opt/safeincloud/delayed-autostart.sh` or remove that duplicate entry after backing it up.
