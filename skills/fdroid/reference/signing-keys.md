# Signing keys, stores and the choice you can't undo

Marks as in `process.md`. Docs: https://f-droid.org/docs/Reproducible_Builds/ and
https://f-droid.org/docs/Signing_Process/ .

## The decision that matters most

| You choose | F-Droid signs with | Users can switch between your other store builds and F-Droid | Can it change later? |
| --- | --- | --- | --- |
| Reproducible build (`Binaries`/`binary:` + `AllowedAPKSigningKeys`) and it verifies | **your key** | yes, upgrades install over each other | you can still drop it, but see next row |
| No reproducible build | **F-Droid's key** | no, users must uninstall to switch | **No.** The MR template says it plainly: if you don't enable it now, the APK is signed with F-Droid's key and you can't enable it later. |

So: decide before the app goes in. If an author says "I can't make it byte-identical, so I'll
drop `Binaries`", tell them this table first. The usual reason is a misunderstanding, not a real
limit (`reproducible.md`).

There is a third option for apps already in F-Droid under F-Droid's key: publish both
developer-signed and F-Droid-signed APKs by adding the developer's signatures to fdroiddata
(`fdroid signatures <apk>` extracts them). That's a maintainer-level change; mention it, don't
promise it. [docs]

## One key for every store

Cross-store upgrades only work when every APK carries the same signing certificate. A setup that
worked for a real app, with Play, F-Droid and GitHub releases all on one key: [seen]

1. Keep one upload keystore you control (a `.jks` outside the repo, with a backup).
2. Make **Play App Signing use that same key**: in Play Console, App signing → "Change app
   signing key" → "Export and upload a key from a Java keystore". Run Google's PEPK tool on the
   keystore with the encryption public key Play gives you (`--include-cert --rsa-aes-encryption`),
   upload the resulting zip, and confirm both Play fingerprints now equal your keystore's.
3. Put that fingerprint in `AllowedAPKSigningKeys`. F-Droid needed no other change.
4. Version codes: Play `10 * code + 0`, F-Droid ABI builds `10 * code + 1..4`, so for one release
   F-Droid's builds outrank Play's and the next Play release outranks all of the previous F-Droid ones.

Trade-off, stated plainly: the upload key and app-signing key become the same key, and Google holds
a copy. Fine for a hobby app; a conscious decision for anything larger.

Cloud-built apps (EAS and similar) keep the keystore on their servers: export it first
(`eas credentials`), and never use a cloud-built APK as the F-Droid reference. [seen]

## Fingerprints

```bash
apksigner verify --print-certs app.apk | grep 'SHA-256'          # colon-free lowercase for the YAML
keytool -printcert -jarfile app.apk | sed -n 's/[[:space:]]*SHA256: //p' | tr -d ':' | tr 'A-F' 'a-f'
keytool -list -v -keystore your.jks        # the key you are about to sign with
```

`AllowedAPKSigningKeys` is lowercase hex, 64 characters. A single signer only. If the value in the
recipe changes between submissions (it did, twice, on one MR we read), the uploaded reference APK
isn't one consistent artifact: find out which key actually signed the file F-Droid downloads.

## Key hygiene

- Reviewers say "keep your signing key safe with backup" every time. Lose it and you can never
  update the app for users who installed it. Back up the keystore and its passwords in two places.
- Don't commit keystores or passwords. Pass passwords through environment variables
  (`scripts/sign-reference.sh` does) so they never appear in shell history or process lists.
- A different key per store defeats cross-store upgrades; a new key invalidates every existing
  install. Android supports signing-key rotation (APK Signature Scheme v3 lineage); F-Droid's
  `AllowedAPKSigningKeys` takes one fingerprint and doesn't support multiple signers. Plan to keep
  one key. [docs; rotation is not something we've done]

## apksigner versions

The reproducible-builds page warns that `apksigner` from build-tools 35.0.0-rc1 and later could
produce APKs that `apksigcopier` cannot verify, and recommends build-tools 34. We signed reference
APKs with **build-tools 36.0.0** using `--v1-signing-enabled false --alignment-preserved true`
against F-Droid's unsigned output, and verification passed on every release (dozens of APKs). So:
use those flags; if verification fails with a good unsigned input and flags, try build-tools 34
before changing anything else. [docs + seen]
