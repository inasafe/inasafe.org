#!/usr/bin/env node
// Bulk-converts the legacy static WordPress HTML export under docs/{news,events,cases,
// about-inasafe,for-*} into mkdocs Markdown under docs/{news,events,case-studies,about,
// contributing}. Structural (depth-counted div matching), not regex-only, since no HTML
// DOM parser was installable in the sandbox this was first run in (no python3/bs4, no
// npm registry access). Safe to re-run: it only ever writes into the destination paths.
import fs from "node:fs";
import path from "node:path";

const ROOT = path.resolve(import.meta.dirname, "..");
const DOCS = path.join(ROOT, "docs");

function readIfExists(p) {
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8") : null;
}

function decodeEntities(s) {
  return s
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#8217;/g, "’")
    .replace(/&#8216;/g, "‘")
    .replace(/&#8211;/g, "–")
    .replace(/&#8212;/g, "—")
    .replace(/&#8230;/g, "…")
    .replace(/&#039;/g, "'");
}

// Find the span of a tag whose opening match is at `openIdx`, by counting nested
// same-named tag opens/closes from there. Returns [contentStart, contentEnd] (exclusive).
function matchTagSpan(html, tagName, openIdx) {
  const openRe = new RegExp(`<${tagName}\\b`, "gi");
  const closeRe = new RegExp(`</${tagName}>`, "gi");
  const contentStart = html.indexOf(">", openIdx) + 1;
  let depth = 1;
  let pos = contentStart;
  while (depth > 0) {
    openRe.lastIndex = pos;
    closeRe.lastIndex = pos;
    const nextOpen = openRe.exec(html);
    const nextClose = closeRe.exec(html);
    if (!nextClose) return [contentStart, html.length];
    if (nextOpen && nextOpen.index < nextClose.index) {
      depth++;
      pos = nextOpen.index + 1;
    } else {
      depth--;
      pos = nextClose.index + closeRe.source.length;
      if (depth === 0) return [contentStart, nextClose.index];
    }
  }
  return [contentStart, html.length];
}

function htmlToMarkdown(html) {
  let md = html;
  let flagged = false;
  if (/\[[a-z_-]+[ \]]|<iframe|class="gallery"|wp-block-embed/i.test(md)) flagged = true;

  md = md.replace(/<!--[\s\S]*?-->/g, "");
  md = md.replace(/<script[\s\S]*?<\/script>/gi, "");
  md = md.replace(/<style[\s\S]*?<\/style>/gi, "");
  md = md.replace(/<h([2-4])[^>]*>([\s\S]*?)<\/h\1>/gi, (_, n, t) => `\n${"#".repeat(Number(n))} ${stripTags(t).trim()}\n`);
  md = md.replace(/<img[^>]*\bsrc="([^"]+)"[^>]*\balt="([^"]*)"[^>]*>/gi, (_, src, alt) => `![${alt}](${src})`);
  md = md.replace(/<img[^>]*\bsrc="([^"]+)"[^>]*>/gi, (_, src) => `![](${src})`);
  md = md.replace(/<a[^>]*\bhref="([^"]+)"[^>]*>([\s\S]*?)<\/a>/gi, (_, href, t) => `[${stripTags(t).trim()}](${href})`);
  md = md.replace(/<(strong|b)>([\s\S]*?)<\/\1>/gi, (_, _t, t) => `**${stripTags(t).trim()}**`);
  md = md.replace(/<(em|i)>([\s\S]*?)<\/\1>/gi, (_, _t, t) => `*${stripTags(t).trim()}*`);
  md = md.replace(/<blockquote[^>]*>([\s\S]*?)<\/blockquote>/gi, (_, t) => `\n> ${stripTags(t).trim()}\n`);
  md = md.replace(/<li[^>]*>([\s\S]*?)<\/li>/gi, (_, t) => `- ${stripTags(t).trim()}\n`);
  md = md.replace(/<\/?(ul|ol)[^>]*>/gi, "\n");
  md = md.replace(/<p[^>]*>([\s\S]*?)<\/p>/gi, (_, t) => `\n${stripTags(t).trim()}\n`);
  md = md.replace(/<br\s*\/?>/gi, "\n");
  md = stripTags(md);
  md = decodeEntities(md);
  md = md.replace(/\n{3,}/g, "\n\n").trim();
  return { md, flagged };
}

function stripTags(s) {
  return s.replace(/<[^>]+>/g, "");
}

function frontmatter(obj) {
  const lines = ["---"];
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined || v === null || v === "") continue;
    if (Array.isArray(v)) lines.push(`${k}: [${v.map((x) => JSON.stringify(x)).join(", ")}]`);
    else lines.push(`${k}: ${JSON.stringify(v)}`);
  }
  lines.push("---", "");
  return lines.join("\n");
}

function slugTitle(slug) {
  return slug.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

// --- Bucket A: WP "post" types (news/events/cases) — <article class="... hentry">
//     containing <h1 class="entry-title"> + <time class="entry-date" datetime=...> +
//     <div class="entry-content">.
function extractPost(html) {
  const artIdx = html.indexOf('<article');
  if (artIdx === -1) return null;
  const [artStart, artEnd] = matchTagSpan(html, "article", artIdx);
  const article = html.slice(artStart, artEnd);

  const titleM = article.match(/<h1 class="entry-title">([\s\S]*?)<\/h1>/);
  const title = titleM ? decodeEntities(stripTags(titleM[1])).trim() : null;

  const dateM = article.match(/<time class="entry-date" datetime="([^"]+)"/);
  const date = dateM ? dateM[1].slice(0, 10) : null;

  const authorM = article.match(/class="url fn n"[^>]*>([^<]+)<\/a>/);
  const author = authorM ? decodeEntities(authorM[1]).trim() : null;

  const tagsM = [...article.matchAll(/rel="tag">([^<]+)<\/a>/g)].map((m) => decodeEntities(m[1]).trim());

  const contentIdx = article.indexOf('<div class="entry-content">');
  if (contentIdx === -1) return { title, date, author, tags: tagsM, body: "", flagged: true };
  const [cs, ce] = matchTagSpan(article, "div", contentIdx);
  const { md, flagged } = htmlToMarkdown(article.slice(cs, ce));
  return { title, date, author, tags: tagsM, body: md, flagged };
}

// --- Bucket B: WP "page" templates (about-inasafe/*, for-*) — no <article>/.entry-content;
//     content lives loose inside <main class="main ...">. Best-effort extraction.
function extractPage(html) {
  const titleM = html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/);
  const title = titleM ? decodeEntities(stripTags(titleM[1])).trim() : null;
  const mainIdx = html.indexOf('<main');
  if (mainIdx === -1) return { title, body: "", flagged: true };
  const [ms, me] = matchTagSpan(html, "main", mainIdx);
  const { md, flagged } = htmlToMarkdown(html.slice(ms, me));
  return { title, body: md, flagged };
}

function writePost({ srcFile, destFile, dateFallback }) {
  const html = readIfExists(srcFile);
  if (!html) return null;
  const r = extractPost(html);
  if (!r) return null;
  const banner = r.flagged ? "<!-- TODO: manual-review — original page had embeds/shortcodes/galleries that may not have converted cleanly -->\n\n" : "";
  const fm = frontmatter({ title: r.title, date: r.date || dateFallback, author: r.author, tags: r.tags.length ? r.tags : undefined });
  fs.mkdirSync(path.dirname(destFile), { recursive: true });
  fs.writeFileSync(destFile, fm + banner + `# ${r.title || slugTitle(path.basename(destFile, ".md"))}\n\n` + r.body + "\n");
  return { title: r.title, date: r.date, flagged: r.flagged, destFile };
}

function writePage({ srcFile, destFile, titleFallback }) {
  const html = readIfExists(srcFile);
  if (!html) return null;
  const r = extractPage(html);
  const banner = "<!-- TODO: manual-review — page-builder template, verify formatting/completeness against the original -->\n\n";
  const title = r.title || titleFallback;
  const fm = frontmatter({ title });
  fs.mkdirSync(path.dirname(destFile), { recursive: true });
  fs.writeFileSync(destFile, fm + banner + `# ${title}\n\n` + (r.body || "_(no extractable body content found in the original page)_") + "\n");
  return { title, flagged: true, destFile };
}

const report = { news: [], events: [], cases: [], about: [], contributing: [], skipped: [] };

// NEWS
for (const slug of fs.readdirSync(path.join(DOCS, "news"))) {
  const srcFile = path.join(DOCS, "news", slug, "index.html");
  if (!fs.existsSync(srcFile)) continue;
  const r = writePost({ srcFile, destFile: path.join(DOCS, "news", `${slug}.md`) });
  if (r) report.news.push({ slug, ...r });
}

// EVENTS (English top-level dirs only; skip numeric-id duplicate "2834")
for (const slug of fs.readdirSync(path.join(DOCS, "events"))) {
  if (!/^[a-z]/.test(slug)) { report.skipped.push(`events/${slug} (non-slug duplicate)`); continue; }
  const srcFile = path.join(DOCS, "events", slug, "index.html");
  if (!fs.existsSync(srcFile)) continue;
  const r = writePost({ srcFile, destFile: path.join(DOCS, "events", `${slug}.md`) });
  if (r) report.events.push({ slug, ...r });
}

// CASES (skip the "@lang=" query-string artifacts and the redundant about-inasafe/cases listing)
for (const slug of fs.readdirSync(path.join(DOCS, "cases"))) {
  if (slug.includes("@") || slug === "index.html") { report.skipped.push(`cases/${slug} (locale-query-string duplicate)`); continue; }
  const srcFile = path.join(DOCS, "cases", slug, "index.html");
  if (!fs.existsSync(srcFile)) continue;
  const r = writePost({ srcFile, destFile: path.join(DOCS, "case-studies", `${slug}.md`) });
  if (r) report.cases.push({ slug, ...r });
}
report.skipped.push("about-inasafe/cases (redundant listing page, superseded by docs/case-studies/index.md)");

// ABOUT (page-template pages)
const ABOUT_PAGES = [
  ["about-inasafe/governance/index.html", "about/governance.md", "Governance"],
  ["about-inasafe/governance/release-rules/index.html", "about/governance-release-rules.md", "Release Rules"],
  ["about-inasafe/governance/roles-responsibilities/index.html", "about/governance-roles-responsibilities.md", "Roles & Responsibilities"],
  ["about-inasafe/partners/index.html", "about/partners.md", "Partners"],
  ["about-inasafe/people/index.html", "about/people.md", "People"],
  ["about-inasafe/press/index.html", "about/press.md", "Press"],
  ["about-inasafe/supporters/index.html", "about/supporters.md", "Supporters"],
];
for (const [src, dest, fallbackTitle] of ABOUT_PAGES) {
  const r = writePage({ srcFile: path.join(DOCS, src), destFile: path.join(DOCS, dest), titleFallback: fallbackTitle });
  if (r) report.about.push({ src, ...r });
}
report.skipped.push("about-inasafe/{flyers,screenshots,videos} (asset galleries, not article content)");

// CONTRIBUTING (page-template pages; for-contributors has no own content, and its nested
// for-coders copy duplicates the top-level for-coders page, so both are skipped)
const CONTRIB_PAGES = [
  ["for-users/index.html", "contributing/users.md", "For Users"],
  ["for-coders/index.html", "contributing/coders.md", "For Coders"],
  ["for-translators/index.html", "contributing/translators.md", "For Translators"],
  ["for-documentation-writers-and-designers/index.html", "contributing/documentation-writers-and-designers.md", "For Documentation Writers & Designers"],
];
for (const [src, dest, fallbackTitle] of CONTRIB_PAGES) {
  const r = writePage({ srcFile: path.join(DOCS, src), destFile: path.join(DOCS, dest), titleFallback: fallbackTitle });
  if (r) report.contributing.push({ src, ...r });
}
report.skipped.push("for-contributors/ (no own content; its nested for-coders/ duplicates the top-level for-coders page)");

// --- Index pages ---
function newsEventsIndex(items, heading) {
  const sorted = [...items].sort((a, b) => (b.date || "").localeCompare(a.date || ""));
  const lines = [`# ${heading}`, ""];
  for (const it of sorted) lines.push(`- [${it.title}](${path.basename(it.destFile)})${it.date ? ` — ${it.date}` : ""}`);
  return lines.join("\n") + "\n";
}
fs.writeFileSync(path.join(DOCS, "news/index.md"), newsEventsIndex(report.news, "News"));
fs.writeFileSync(path.join(DOCS, "events/index.md"), newsEventsIndex(report.events, "Events"));
fs.writeFileSync(
  path.join(DOCS, "case-studies/index.md"),
  "# Case Studies\n\n" + report.cases.map((it) => `- [${it.title}](${path.basename(it.destFile)})`).join("\n") + "\n"
);
fs.writeFileSync(
  path.join(DOCS, "about/index.md"),
  "# About InaSAFE\n\n" + report.about.map((it) => `- [${it.title}](${path.basename(it.destFile)})`).join("\n") + "\n"
);
fs.writeFileSync(
  path.join(DOCS, "contributing/index.md"),
  "# Contributing\n\n" + report.contributing.map((it) => `- [${it.title}](${path.basename(it.destFile)})`).join("\n") + "\n"
);

// --- Rehome wp-content/uploads image references into per-section assets/ dirs ---
const SECTION_DIRS = ["news", "events", "case-studies", "about", "contributing"];
let imagesCopied = 0;
for (const section of SECTION_DIRS) {
  const dir = path.join(DOCS, section);
  if (!fs.existsSync(dir)) continue;
  for (const file of fs.readdirSync(dir)) {
    if (!file.endsWith(".md")) continue;
    const fp = path.join(dir, file);
    let text = fs.readFileSync(fp, "utf8");
    const before = text;
    text = text.replace(/(\.\.\/)*wp-content\/uploads\/([^)"\s]+)/g, (_, _up, rel) => {
      const srcAbs = path.join(DOCS, "wp-content/uploads", rel);
      if (!fs.existsSync(srcAbs)) return `wp-content/uploads/${rel}`; // leave as-is, flagged by absence
      const base = path.basename(rel);
      const destAbs = path.join(dir, "assets", base);
      fs.mkdirSync(path.dirname(destAbs), { recursive: true });
      fs.copyFileSync(srcAbs, destAbs);
      imagesCopied++;
      return `assets/${base}`;
    });
    if (text !== before) fs.writeFileSync(fp, text);
  }
}
report.imagesCopied = imagesCopied;

console.log(JSON.stringify(report, null, 2));
