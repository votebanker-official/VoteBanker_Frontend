import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const indianPath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'lib',
  'app',
  'localization',
  'translations',
  'indian.dart',
);

let content = fs.readFileSync(indianPath, 'utf8');

function portfolioTemplateFromTitle(title) {
  return title
    .replace(/ৱেবছাইট/g, 'টেমপ্লেট')
    .replace(/ওয়েবসাইট/g, 'টেমপ্লেট')
    .replace(/ৱেবসাইট/g, 'টেমপ্লেট')
    .replace(/वेबसाइट/g, 'टेम्प्लेट')
    .replace(/वेबसायट/g, 'टेम्प्लेट')
    .replace(/जालस्थलम्/g, 'टेम्प्लेटम्')
    .replace(/વેબસાઇટ/g, 'ટેમ્પ્લેટ')
    .replace(/ਵੈੱਬਸਾਈਟ/g, 'ਟੈਂਪਲੇਟ')
    .replace(/ୱେବସାଇଟ/g, 'ଟେମ୍ପଲେଟ')
    .replace(/ᱣᱮᱵᱥᱟᱭᱤᱴ/g, 'ᱴᱮᱢᱯᱞᱮᱴ')
    .replace(/ويب سائيٽ/g, 'ٽيمپليٽ')
    .replace(/ویب سائٹ/g, 'ٹیمپلیٹ');
}

content = content.replace(
  /('websiteTitle': '([^']*)',)(\r?\n(?!\s*'chooseWebsiteTemplate'))/g,
  (match, titleLine, title, next) => {
    const choose = portfolioTemplateFromTitle(title);
    return `${titleLine}${next}  'chooseWebsiteTemplate': '${choose}',${next}`;
  },
);

fs.writeFileSync(indianPath, content, 'utf8');
console.log('inserted', (content.match(/chooseWebsiteTemplate/g) || []).length, 'entries');
