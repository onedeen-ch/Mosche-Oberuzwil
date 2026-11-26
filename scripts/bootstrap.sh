#!/usr/bin/env bash
set -euo pipefail
tmp="$(mktemp -d)"
flutter create --no-pub --org ch.sigoberuzwil --project-name sig_oberuzwil --platforms android,ios "$tmp/sig_oberuzwil"
for p in android ios; do
  if [ ! -d "$p" ]; then cp -R "$tmp/sig_oberuzwil/$p" "$p"; fi
done
python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/main/AndroidManifest.xml')
s=p.read_text().replace('android:label="sig_oberuzwil"','android:label="SIG Oberuzwil"')
if 'android.permission.INTERNET' not in s: s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET"/>\n    <application',1)
p.write_text(s)
p=Path('ios/Runner/Info.plist')
p.write_text(p.read_text().replace('<string>Sig Oberuzwil</string>','<string>SIG Oberuzwil</string>').replace('<string>sig_oberuzwil</string>','<string>SIG Oberuzwil</string>'))
PY
rm -rf "$tmp"
