#!/usr/bin/env node
const express = require("express");
const os = require("os");
const path = require("path");
const debounce = require("debounce");
const fetch = require("node-fetch");
const { RBTree } = require("bintrees");
const { watch, readFileSync, writeFile, readFile, existsSync } = require("fs");
const app = express();
const port = 2021;
const mruJsonPath = path.join(os.homedir(), ".local/share/jsMRU.json");

if (!existsSync(mruJsonPath)) {
  writeFileSync(mruJsonPath, "{}");
}

const treeComparator = (a, b) => b.date - a.date;
let mru = JSON.parse(readFileSync(mruJsonPath));
const tree = new RBTree(treeComparator);

function buildTree() {
  Object.entries(mru).forEach(([filename, values]) => {
    tree.insert({ filename, ...values });
  });
}
buildTree();

let skipChangedFile;

watch(
  mruJsonPath,
  debounce(() => {
    if (skipChangedFile) {
      skipChangedFile = false;
      return;
    }
    readFile(mruJsonPath, (err, data) => {
      try {
        if (!err) {
          mru = JSON.parse(data);
          tree.clear();
          buildTree();
        }
      } catch (e) {}
    });
  }, 200)
);
const writeMru = debounce(() => {
  skipChangedFile = true;
  writeFile(mruJsonPath, JSON.stringify(mru), (err) => {
    if (err) {
      console.log({ err });
    }
  });
}, 300);
fetch(`http://localhost:${port}/ping`, { timeout: 15 })
  .then(() => {
    console.log("port is taken, assuming intance of jsmru");
    process.exit(0);
  })
  .catch(() => {
    app.use(express.json());
    app.get("/", (req, res) => {
      const result = [];
      tree.each(({ filename, line, column }) =>
        result.push(`${filename}:${line}:${column}`)
      );
      res.send(result.join("\n"));
    });

    app.post("/mru", (req, res) => {
      let { filepath, line, column, event, date = Date.now() } = req.body;
      res.sendStatus(200);
      if (filepath.startsWith("/private/var/folders/")) return;
      const oldData = mru[filepath];
      if (
        filepath !== mruJsonPath && //mruJson will allways rewrite to single line
        line + column === 2 && // line 1 column 1
        oldData &&
        /(BufWinEnter|BufReadPost|WinEnter)/.test(event)
      ) {
        ({ line, column } = oldData);
      }
      if (mru[filepath]) {
        tree.remove(mru[filepath]);
      }
      mru[filepath] = { line, column, date };
      tree.insert({ filename: filepath, ...mru[filepath] });
      if (filepath !== mruJsonPath) {
        writeMru();
      }
    });

    app.get("/removeMruInvalidEntries", (req, res) => {
      debugger;
      const deleted = [];
      for (const [filename, value] of Object.entries(mru)) {
        if (!existsSync(filename)) {
          tree.remove({ filename, ...value });
          delete mru[filename];
          deleted.push(filename);
        }
      }
      writeMru();
      res.send(deleted.join("\n"));
    });

    app.listen(port, () => {
      console.log(`Example app listening at http://localhost:${port}`);
    });
  });
