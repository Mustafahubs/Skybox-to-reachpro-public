# Skybox to ReachPro — releases

This repo holds **built releases** only: the Windows exe, its SHA256 checksum, and this install script. Application source is in the private `Skybox-to-reachpro-by-api` repo. This public repo lets operators install and self-update **without** GitHub credentials.

## Install (new PC — no existing exe)

**PowerShell:**

```powershell
irm https://raw.githubusercontent.com/Mustafahubs/Skybox-to-reachpro-public/main/install.ps1 | iex
```

**Command Prompt (cmd.exe):**

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Join-Path $env:TEMP 'reachpro-install.ps1'; iwr -UseBasicParsing 'https://raw.githubusercontent.com/Mustafahubs/Skybox-to-reachpro-public/main/install.ps1' -OutFile $p; & $p"
```

This downloads the latest [Release](https://github.com/Mustafahubs/Skybox-to-reachpro-public/releases/latest), verifies SHA256, installs to `Documents\Skybox-to-reachpro`, adds Start Menu / Desktop shortcuts, and launches the app. No administrator rights required.

After install, copy your `.env` (StubHub / ReachPro settings) into that folder next to the exe.

Safe to re-run to reinstall or force-update — close the app first if it is running.

## Updates after the first install

The exe checks for newer releases on each launch and asks before downloading. You normally do **not** need to run the installer again.

## Manual download

Release assets: `skybox_to_reachpro.exe` and `skybox_to_reachpro.exe.sha256`.
