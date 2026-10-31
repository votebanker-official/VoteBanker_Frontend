const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadMap(file) {
  const text = fs.readFileSync(file, "utf8");
  const match = text.match(/<String, String>\{([\s\S]*)\};/);
  if (!match) throw new Error(`no map in ${file}`);
  return vm.runInNewContext(`({${match[1]}})`);
}

function appendMissing(file, missing) {
  let text = fs.readFileSync(file, "utf8");
  const additions = Object.entries(missing).map(
    ([key, value]) => `  '${key}': '${String(value).replace(/'/g, "\\'")}',`
  );
  text = text.replace(/\n};\s*$/, `\n${additions.join("\n")}\n};\n`);
  fs.writeFileSync(file, text, "utf8");
}

const dir = path.join(__dirname, "..", "lib", "app", "localization", "translations");
const en = loadMap(path.join(dir, "en.dart"));
for (const name of ["hi.dart", "kn.dart", "ml.dart", "ta.dart", "te.dart"]) {
  const full = path.join(dir, name);
  const map = loadMap(full);
  const missing = {};
  for (const [key, value] of Object.entries(en)) {
    if (!(key in map)) missing[key] = value;
  }
  if (Object.keys(missing).length) appendMissing(full, missing);
  console.log(name, Object.keys(missing).length);
}
