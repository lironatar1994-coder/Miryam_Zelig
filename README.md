# Miryam Zelig Static Site

Static production page for Miryam Zelig.

## Files

- `index.html` - the complete static site.
- `deploy.ps1` - local Windows deploy entrypoint.
- `deploy_linux.sh` - server-side deploy script.

## Deployment

From this folder:

```powershell
.\deploy.ps1 -CommitMessage "Update site"
```

The script pushes `main` to:

```text
https://github.com/lironatar1994-coder/Miryam_Zelig.git
```

Then it deploys on the Linux server from:

```text
/root/Miryam_Zelig
```

Default public route:

```text
https://vee-app.co.il/Miryam_Zelig/
```

To deploy to a different domain or path, update `ROUTE_BASE`, `WEB_ROOT`, `NGINX_SITE`, and `NGINX_SNIPPET` in `deploy_linux.sh`.
