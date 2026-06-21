# Code signing & notarization

By default Sweep builds are **ad-hoc signed**, so macOS Gatekeeper shows a
warning on first launch. To distribute a build that opens cleanly (no
right-click → Open dance), it must be **signed with a Developer ID Application
certificate and notarized by Apple**.

This is fully optional and the build pipeline works without it — but here is how
to set it up.

## Prerequisites

- A paid **Apple Developer Program** membership.
- Xcode command-line tools (`notarytool`, `stapler`, `codesign`).

## 1. Create a "Developer ID Application" certificate

This certificate is different from "Apple Development" / "Apple Distribution"
(those are for debugging / the App Store). Easiest path — via Xcode:

1. **Xcode → Settings → Accounts**, select your team.
2. **Manage Certificates… → + → Developer ID Application**.
3. It appears in your login keychain. Verify:
   ```bash
   security find-identity -v -p codesigning | grep "Developer ID Application"
   ```

(Alternatively create it at <https://developer.apple.com/account/resources/certificates>.)

## 2. Create notarization credentials (App Store Connect API key)

1. <https://appstoreconnect.apple.com> → **Users and Access → Integrations →
   App Store Connect API**.
2. **Generate API Key** with the **Developer** role.
3. Download the `AuthKey_XXXXXXXXXX.p8` (**you can only download it once**).
4. Note the **Key ID** and the **Issuer ID** shown on that page.

> Alternative: an app-specific password (Apple ID → Sign-In and Security →
> App-Specific Passwords). Then use `NOTARY_APPLE_ID`, `NOTARY_PASSWORD`,
> `NOTARY_TEAM_ID` instead of the API-key variables below.

## 3. Build a notarized DMG locally

```bash
export NOTARY_KEY="$HOME/keys/AuthKey_XXXXXXXXXX.p8"
export NOTARY_KEY_ID="XXXXXXXXXX"
export NOTARY_ISSUER="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

./scripts/notarize.sh 0.1.0
```

The script signs the app (hardened runtime), notarizes and staples it, packages
the DMG, then notarizes and staples the DMG. Verify:

```bash
xcrun stapler validate dist/Sweep-0.1.0.dmg
spctl --assess --type open --context context:primary-signature -vv dist/Sweep-0.1.0.dmg
```

## 4. Automatic notarized releases in CI

Configure these **repository secrets**, then every `v*` tag is built, notarized
and published automatically by [`release.yml`](.github/workflows/release.yml).
(Without them, CI still publishes an ad-hoc DMG.)

| Secret | Value |
|--------|-------|
| `MACOS_CERT_P12` | base64 of your exported Developer ID `.p12` |
| `MACOS_CERT_PASSWORD` | password you set when exporting the `.p12` |
| `NOTARY_KEY_P8` | base64 of the `AuthKey_*.p8` |
| `NOTARY_KEY_ID` | the API Key ID |
| `NOTARY_ISSUER` | the API Issuer ID |

Export the certificate from **Keychain Access** (right-click the Developer ID
Application identity → **Export…** → `.p12` with a password), then:

```bash
# encode the binaries to base64
base64 -i DeveloperID.p12   | pbcopy   # → paste into MACOS_CERT_P12
base64 -i AuthKey_XXXX.p8   | pbcopy   # → paste into NOTARY_KEY_P8

# or set them straight from files with the gh CLI:
gh secret set MACOS_CERT_P12     < <(base64 -i DeveloperID.p12)
gh secret set NOTARY_KEY_P8      < <(base64 -i AuthKey_XXXXXXXXXX.p8)
gh secret set MACOS_CERT_PASSWORD            # prompts for the value
gh secret set NOTARY_KEY_ID                  # prompts
gh secret set NOTARY_ISSUER                  # prompts
```

Then cut a release:

```bash
git tag v0.2.0 && git push origin v0.2.0
```

## Notes

- The app requests no special entitlements; it relies on **Full Disk Access**
  (a TCC permission the user grants), not on a sandbox entitlement.
- Keep the `.p8` and `.p12` files out of the repo — they are secrets.
