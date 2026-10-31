const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'lib', 'app', 'localization', 'translations');

function findBad(buf) {
  const bad = [];
  for (let i = 0; i < buf.length; i++) {
    const b = buf[i];
    if (b < 0x80) continue;
    let need = 0;
    if ((b & 0xe0) === 0xc0) need = 1;
    else if ((b & 0xf0) === 0xe0) need = 2;
    else if ((b & 0xf8) === 0xf0) need = 3;
    else {
      bad.push(i);
      continue;
    }
    let ok = true;
    for (let j = 1; j <= need; j++) {
      if (i + j >= buf.length || (buf[i + j] & 0xc0) !== 0x80) {
        ok = false;
        break;
      }
    }
    if (!ok) bad.push(i);
    else i += need;
  }
  return bad;
}

for (const f of fs.readdirSync(dir).filter((x) => x.endsWith('.dart'))) {
  const p = path.join(dir, f);
  const buf = Buffer.from(fs.readFileSync(p));
  const bad = findBad(buf);
  if (!bad.length) {
    console.log('clean', f);
    continue;
  }
  const arr = [...buf];
  for (const i of bad) {
    console.log(
      f,
      'bad@',
      i,
      'byte',
      arr[i].toString(16),
      'ctx',
      JSON.stringify(
        Buffer.from(arr.slice(Math.max(0, i - 30), i + 30)).toString('latin1'),
      ),
    );
    if (arr[i] === 0x96 || arr[i] === 0x97) arr[i] = 0x2d;
    else arr[i] = 0x3f;
  }
  const next = Buffer.from(arr);
  const still = findBad(next);
  if (still.length) {
    throw new Error(`${f} still bad at ${still.join(',')}`);
  }
  fs.writeFileSync(p, next);
  console.log('fixed', f);
}

const extras = {
  en: {
    merchAddPhoto: 'Add your photo',
    merchChangePhoto: 'Change photo',
    merchRemovePhoto: 'Remove photo',
  },
  hi: {
    merchAddPhoto: 'अपनी फ़ोटो जोड़ें',
    merchChangePhoto: 'फ़ोटो बदलें',
    merchRemovePhoto: 'फ़ोटो हटाएँ',
  },
  kn: {
    merchAddPhoto: 'ನಿಮ್ಮ ಫೋಟೋ ಸೇರಿಸಿ',
    merchChangePhoto: 'ಫೋಟೋ ಬದಲಾಯಿಸಿ',
    merchRemovePhoto: 'ಫೋಟೋ ತೆಗೆದುಹಾಕಿ',
  },
  ml: {
    merchAddPhoto: 'നിങ്ങളുടെ ഫോട്ടോ ചേർക്കുക',
    merchChangePhoto: 'ഫോട്ടോ മാറ്റുക',
    merchRemovePhoto: 'ഫോട്ടോ നീക്കം ചെയ്യുക',
  },
  ta: {
    merchAddPhoto: 'உங்கள் புகைப்படத்தைச் சேர்க்கவும்',
    merchChangePhoto: 'புகைப்படத்தை மாற்றவும்',
    merchRemovePhoto: 'புகைப்படத்தை நீக்கவும்',
  },
  te: {
    merchAddPhoto: 'మీ ఫోటోను జోడించండి',
    merchChangePhoto: 'ఫోటో మార్చండి',
    merchRemovePhoto: 'ఫోటో తొలగించండి',
  },
};

function esc(s) {
  return s.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

for (const [lang, map] of Object.entries(extras)) {
  const p = path.join(dir, `${lang}.dart`);
  let t = fs.readFileSync(p, 'utf8');
  for (const [k, v] of Object.entries(map)) {
    if (new RegExp(`'${k}'\\s*:`).test(t)) continue;
    const entry = `  '${k}': '${esc(v)}',`;
    const idx = t.lastIndexOf('\n};');
    t = `${t.slice(0, idx)}\n${entry}${t.slice(idx)}`;
  }
  fs.writeFileSync(p, t, 'utf8');
  const finalText = fs.readFileSync(p, 'utf8');
  console.log(
    'keys',
    lang,
    Object.keys(map).every((k) => finalText.includes(`'${k}'`)),
  );
}
