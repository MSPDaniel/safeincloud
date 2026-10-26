# Publish SafeInCloud to GitHub Container Registry and install on Unraid

## Security and architecture

This repository contains **only** the Docker build, launcher scripts, and template. It does not include proprietary SafeInCloud Windows binaries, the password database, the persistent Wine prefix, or Webtop credentials. Do not commit `source/`, `config/`, or `.env`.

## 1. Create the GitHub repository

Create a repository named `safeincloud` under your GitHub username. Upload the **contents** of this ZIP to the repository root, including `.github/workflows/docker-publish.yml` (GitHub web uploads may hide dotfiles; verify they are included). Prefer a public repository if you want simple unauthenticated Unraid image pulls; you can keep the repository private and make only the GHCR package public if desired.

In GitHub, check Settings > Actions > General > Workflow permissions; the workflow requests `packages: write` and uses the built-in `GITHUB_TOKEN`. The workflow publishes `ghcr.io/mspdaniel/safeincloud:latest` when pushing to `main`, and version tags when pushing `v*` tags. Check Actions for the build outcome; a first build may take a while because the base image and packages are large.

## 2. Make GHCR package pullable

After the first successful build, open your GitHub profile > Packages > `safeincloud` > Package settings, and change package visibility to **Public** for simple Unraid pulls. A private GHCR image requires an authenticated Docker registry login on Unraid.

## 3. Configure Unraid template

The Unraid XML is already configured for GitHub account `MSPDaniel` and image `ghcr.io/mspdaniel/safeincloud:latest`. Commit it to GitHub.

Option A (direct URL): Unraid > Docker > Add Container > Template repositories (or template URL, if supported by your Unraid version/plugin), point to the raw XML URL:

`https://raw.githubusercontent.com/USERNAME/safeincloud/main/unraid/safeincloud.xml`

Option B (reliable manual import): save the edited XML to `/boot/config/plugins/dockerMan/templates-user/my-safeincloud.xml`, then go to Unraid > Docker > Add Container and choose the `safeincloud` template. Back up an existing template before overwriting it.

Unraid's Community Applications catalog **does not automatically index** an XML file merely because it is in GitHub. Community Apps publication is a separate submission process.

## 4. Avoid colliding with your existing working container

If your current Compose-based `safeincloud` container still exists, stop and remove only that container before creating the template-managed container; do **not** remove the image volumes, `/config`, `/source`, or your separate `safeincloud-original` container. Example, after stopping the Compose service:

`cd /mnt/cache/appdata/safeincloud/build && docker compose down`

This removes the Compose container/network, not the bind-mounted data. The XML uses the same container name `safeincloud`, port 3010, and existing persistent mount paths. Verify these match your environment.

## 5. Start and use

The XML template pulls `ghcr.io/mspdaniel/safeincloud:latest`, maps host HTTPS port `3010` to container `3001`, binds `/mnt/cache/appdata/safeincloud/config` to `/config` and `/mnt/cache/appdata/safeincloud/source` read-only to `/opt/safeincloud/source`. Supply Webtop username and password in the template.

Open `https://UNRAID_IP:3010` (the self-signed HTTPS certificate may prompt a browser warning). Your existing database and Wine prefix remain under the persistent config mount. Avoid exposing this service directly to the public internet without a separate strong access control layer.

## 6. Updates

Push to `main`, wait for the Actions workflow to publish `latest`, then in Unraid use Docker > Check for Updates and update the container. A pinned version tag is preferable if you need reproducible rollbacks. Keep a backup of `/mnt/cache/appdata/safeincloud/config` before major changes.

## Notes

- Target platform: `linux/amd64`.
- The Dockerfile uses the moving `lscr.io/linuxserver/webtop:ubuntu-xfce` base tag. For reproducible builds, pin a tested image digest later.
- This is a packaging change only; application launch still uses the tested **5-second** delayed XFCE autostart.
- If you change the repository name, update the XML repository path and GitHub links.
