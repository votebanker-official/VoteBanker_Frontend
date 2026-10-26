import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');
const transDir = path.join(root, 'lib', 'app', 'localization', 'translations');

const NEW_PORTFOLIO_KEYS = [
  'portfolioAboutLeader',
  'portfolioVisionPriorities',
  'portfolioAchievementsWork',
  'portfolioGalleryUpdates',
  'portfolioGetInTouch',
  'portfolioBioPlaceholder',
  'portfolioVisionPlaceholder',
  'portfolioAchievementsPlaceholder',
  'portfolioGalleryPlaceholder',
  'portfolioContactPlaceholder',
  'portfolioPoliticalParty',
  'portfolioYourName',
  'portfolioJoinMission',
  'portfolioNavAchievements',
  'portfolioNavVisionFull',
];

const EN_PORTFOLIO_NEW = {
  portfolioAboutLeader: 'About the Leader',
  portfolioVisionPriorities: 'Vision & Priorities',
  portfolioAchievementsWork: 'Achievements & Development Work',
  portfolioGalleryUpdates: 'Gallery & Community Updates',
  portfolioGetInTouch: 'Get in Touch',
  portfolioBioPlaceholder:
    'Add your biography in Website Details. This section stays text only.',
  portfolioVisionPlaceholder:
    'Share your vision, priorities, and development agenda in Website Details.',
  portfolioAchievementsPlaceholder:
    'Achievements and development projects appear here when you add them.',
  portfolioGalleryPlaceholder:
    'Saved photos, captions, and public updates appear here when available.',
  portfolioContactPlaceholder:
    'A public contact number appears here when you add one.',
  portfolioPoliticalParty: 'Political party',
  portfolioYourName: 'Your name',
  portfolioJoinMission: 'Join Our Mission',
  portfolioNavAchievements: 'Achievements',
  portfolioNavVisionFull: 'Vision & Priorities',
};

const CHOOSE_TEMPLATE = {
  en: 'Portfolio Template',
  hi: 'पोर्टफोलियो टेम्पलेट',
  kn: 'ಪೋರ್ಟ್‌ಫೋಲಿಯೋ ಟೆಂಪ್ಲೇಟ್',
  ml: 'പോർട്ട്‌ഫോളിയോ ടെംപ്ലേറ്റ്',
  ta: 'போர்ட்ஃபோலியோ டெம்ப்ளேட்',
  te: 'పోర్ట్‌ఫోలియో టెంప్లేట్',
};

const CHOOSE_BODY_EN =
  'Preview your professional portfolio site with your profile photo, party branding, and public details. Continue to fill in Website Details.';

function extractKeys(content) {
  const keys = new Set();
  const re = /'([^'\\]+)':/g;
  let m;
  while ((m = re.exec(content)) !== null) keys.add(m[1]);
  return keys;
}

function escapeDartString(s) {
  return s.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function formatEntry(key, value) {
  const esc = escapeDartString(value);
  if (esc.length > 72 && value.includes(' ')) {
    return `  '${key}':\n      '${esc}',`;
  }
  return `  '${key}': '${esc}',`;
}

function upsertKey(content, key, value) {
  const entry = formatEntry(key, value);
  const keyRe = new RegExp(`  '${key.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\$&')}':[^\\n]*(?:\\n      '[^']*',)?`, 'm');
  if (keyRe.test(content)) {
    return content.replace(keyRe, entry);
  }
  return content.replace(/\n};\s*$/, `\n${entry}\n};\n`);
}

function appendMissingKeys(content, entries) {
  const existing = extractKeys(content);
  const lines = [];
  for (const [key, value] of Object.entries(entries)) {
    if (!existing.has(key)) lines.push(formatEntry(key, value));
  }
  if (lines.length === 0) return content;
  return content.replace(/\n};\s*$/, `\n${lines.join('\n')}\n};\n`);
}

function updateEnDart() {
  const enPath = path.join(transDir, 'en.dart');
  let content = fs.readFileSync(enPath, 'utf8');
  content = upsertKey(content, 'chooseWebsiteTemplate', CHOOSE_TEMPLATE.en);
  content = upsertKey(content, 'chooseWebsiteTemplateBody', CHOOSE_BODY_EN);
  const insertAfter = "  'portfolioEditWebsite': 'Edit Website',";
  if (!content.includes("'portfolioAboutLeader'")) {
    const block = NEW_PORTFOLIO_KEYS.map((k) => formatEntry(k, EN_PORTFOLIO_NEW[k])).join('\n');
    content = content.replace(insertAfter, `${insertAfter}\n${block}`);
  }
  fs.writeFileSync(enPath, content, 'utf8');
}

function updateIndianDart() {
  const indianPath = path.join(transDir, 'indian.dart');
  let content = fs.readFileSync(indianPath, 'utf8');
  const chooseByTitle = {
    'প’ৰ্টফলিঅ’ ৱেবছাইট': 'প’ৰ্টফলিঅ’ টেমপ্লেট',
    'পোর্টফোলিও ওয়েবসাইট': 'পোর্টফোলিও টেমপ্লেট',
    'पोर्टफोलियो वेबसाइट': 'पोर्टफोलियो टेम्प्लेट',
    'पोर्टफोलियो वेबसायट': 'पोर्टफोलियो टेम्प्लेट',
    'પોર્ટફોલિયો વેબસાઇટ': 'પોર્ટફોલિયો ટેમ્પ્લેટ',
    'پورٹ فولیو ویب سائٹ': 'پورٹ فولیو ٹیمپلیٹ',
    'পোর্টফোলিও ৱেবসাইট': 'পোর্টফোলিও টেমপ্লেট',
    'पोर्टफोलिओ वेबसाइट': 'पोर्टफोलिओ टेम्प्लेट',
    'ପୋର୍ଟଫୋଲିଓ ୱେବସାଇଟ': 'ପୋର୍ଟଫୋଲିଓ ଟେମ୍ପଲେଟ',
    'ਪੋਰਟਫੋਲੀਓ ਵੈੱਬਸਾਈਟ': 'ਪੋਰਟਫੋਲੀਓ ਟੈਂਪਲੇਟ',
    'पोर्टफोलियो जालस्थलम्': 'पोर्टफोलियो टेम्प्लेटम्',
    'ᱯᱚᱨᱴᱯᱷᱚᱞᱤᱭᱚ ᱣᱮᱵᱥᱟᱭᱤᱴ': 'ᱯᱚᱨᱴᱯᱷᱚᱞᱤᱭᱚ ᱴᱮᱢᱯᱞᱮᱴ',
    'پورٽ فولiyo ويب سائيٽ': 'پورٽ فولiyo ٽيمپليٽ',
    'پورٹ فولiyo ویب سائٹ': 'پورٹ فولiyo ٹیمپلیٹ',
  };
  content = content.replace(
    /('websiteTitle': '([^']*)',)(\r?\n(?!\s*'chooseWebsiteTemplate'))/g,
    (match, titleLine, title, next) => {
      const choose =
        chooseByTitle[title] ??
        title
          .replace(/वेबसाइट|वेबसायट|जालस्थलम्|ৱেবছাইট|ওয়েবসাইট|ৱেবসাইট|વેબસાઇટ|ویب سائٹ|ୱେବସାଇଟ|ਵੈੱਬਸਾਈਟ|ᱣᱮᱵᱥᱟᱭᱤᱴ|ويب سائيٽ/g, 'टेम्प्लेट')
          .replace(/Website|website/gi, 'Template');
      return `${titleLine}\r\n  'chooseWebsiteTemplate': '${choose}',${next}`;
    },
  );
  fs.writeFileSync(indianPath, content, 'utf8');
}

function audit() {
  const enContent = fs.readFileSync(path.join(transDir, 'en.dart'), 'utf8');
  const enKeys = extractKeys(enContent);
  const locales = ['hi', 'kn', 'ml', 'ta', 'te'];
  const report = {};
  for (const loc of locales) {
    const content = fs.readFileSync(path.join(transDir, `${loc}.dart`), 'utf8');
    const keys = extractKeys(content);
    const missing = [...enKeys].filter((k) => !keys.has(k));
    report[loc] = { total: keys.size, missing: missing.length, missingKeys: missing };
  }
  return { enTotal: enKeys.size, report };
}

async function main() {
  const locales = ['hi', 'kn', 'ml', 'ta', 'te'];
  for (const loc of locales) {
    const dataPath = path.join(__dirname, 'locale_data', `${loc}.json`);
    const entries = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
    entries.chooseWebsiteTemplate = CHOOSE_TEMPLATE[loc];
    for (const k of NEW_PORTFOLIO_KEYS) {
      if (!entries[k]) throw new Error(`Missing ${k} in ${loc}.json`);
    }
    const dartPath = path.join(transDir, `${loc}.dart`);
    let content = fs.readFileSync(dartPath, 'utf8');
    content = upsertKey(content, 'chooseWebsiteTemplate', CHOOSE_TEMPLATE[loc]);
    content = appendMissingKeys(content, entries);
    fs.writeFileSync(dartPath, content, 'utf8');
  }
  updateEnDart();
  updateIndianDart();
  const { enTotal, report } = audit();
  console.log('en.dart keys:', enTotal);
  for (const loc of locales) {
    const r = report[loc];
    console.log(`${loc}: ${r.total} keys, missing vs en: ${r.missing}`);
    if (r.missing > 0 && r.missing <= 20) console.log('  ', r.missingKeys.join(', '));
  }
  const enContent = fs.readFileSync(path.join(transDir, 'en.dart'), 'utf8');
  const hiContent = fs.readFileSync(path.join(transDir, 'hi.dart'), 'utf8');
  const getVal = (c, k) => {
    const m = c.match(new RegExp(`'${k}':\\s*'([^']*)'`));
    return m ? m[1] : c.match(new RegExp(`'${k}':\\s*\\n\\s*'([^']*)'`))?.[1];
  };
  console.log('chooseWebsiteTemplate en:', getVal(enContent, 'chooseWebsiteTemplate'));
  console.log('chooseWebsiteTemplate hi:', getVal(hiContent, 'chooseWebsiteTemplate'));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
