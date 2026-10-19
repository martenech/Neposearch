# Neposearch – TODO

Všetky dáta ostávajú lokálne v ObjectBoxe. Na Claude idú len texty na zhrnutie (ako pri súboroch).
Citlivé zdroje (Mail, Správy) sú voliteľné so samostatným vypínačom.

## Fáza 1 – dáta bez nových povolení
- [x] **Spotlight metadáta súborov** – odkiaľ bol stiahnutý (URL/e-mail), kedy naposledy otvorený, počet otvorení,
      Finder tagy, autor, komentár. Hľadateľné („stiahnuté z banky“), nedávne súbory podľa posledného otvorenia.
- [x] **História Claude Code** (`~/.claude/projects/*/*.jsonl`) – sedenia po projektoch, hľadanie v nich,
      ↩ pokračuje v sedení (`claude --resume`) v termináli v priečinku projektu.
- [x] **História terminálu** (fish, zsh) – hľadanie príkazov, ↩ skopíruje / vloží príkaz.
- [x] Git commity v `~/Projects` (popisy commitov, vetvy).
- [-] História a záložky Chrome / Arc / Brave – presunuté k Safari vo Fáze 3.

## Fáza 2 – Nepomuk: osoby, firmy, stretnutia
- [x] **Kontakty** (povolenie) – entity Osoba/Firma v ObjectBoxe.
- [x] **Kalendár a Pripomienky** (povolenie) – stretnutia, účastníci, úlohy.
- [x] Claude roztriedi vlastné mená z kľúčových slov (osoby/firmy/projekty/miesta) → prepojenia (ObjectBox ToMany) so súbormi.
- [ ] Miesta (108 roztriedených) ako entity; prepojenie stretnutí so súbormi.
- [x] Hľadanie „všetko k projektu Acme“, „čo mám od Jany“, „podklady na zajtrajšie stretnutie“.

## Fáza 3 – ďalšie zdroje
- [-] **Apple Notes** – vynechané (JXA by Poznámky spúšťal na pozadí).
- [x] **Mail** (Full Disk Access) – predmet, odosielateľ, úryvok; e-maily od osoby v „všetko súvisiace“.
- [ ] Mail: AI zhrnutia vlákien, prílohy, prepojenie s firmami.
- [ ] Správy (Full Disk Access, voliteľné).
- [x] Safari história, záložky a Zoznam na čítanie (Full Disk Access).

## Ostatné
- [x] Spustenie pri prihlásení (`SMAppService`), inštalácia cez `scripts/bundle.sh --install`.
- [ ] MCP server – Claude Code sa môže pýtať Neposearch (súbory, zhrnutia, vektory).
- [ ] „Podobné súbory“ ako akcia v ⌘K (e5 vektory).
- [ ] AI nad označeným textom (opraviť, preložiť, zhrnúť, prepísať) cez Max predplatné.
- [ ] Projekty z `~/Projects` (VS Code, terminál, Claude Code, GitHub).
- [ ] Quicklinks a hľadanie na webe (`g`, `yt`, `gh`, vlastné).
- [ ] Opýtať sa Claude čokoľvek (odpoveď priamo v pruhu).
- [ ] Upratovanie s AI („uprac Stiahnuté“).
- [ ] Distribúcia na iné Macy: pribaliť `swift-transformers_Hub.bundle` (teraz sa hľadá v `.build`).

## Hotové
- [x] Indexer súborov so zhrnutiami a kľúčovými slovami od Claude (Claude Code predplatné / API / Apple)
- [x] ObjectBox s vektorovým indexom, lokálny model multilingual-e5-small
- [x] Spúšťač (⌥Space): súbory, aplikácie, kalkulačka a meny, okná, systémové príkazy, schránka,
      snippety, screenshoty (OCR), karty prehliadača, Opýtať sa Claude, aliasy, témy
