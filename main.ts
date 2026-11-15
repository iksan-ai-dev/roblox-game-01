// Starfall Rush — a 2D arcade catcher for make.fun's roblox-game-01.
// Node 22, standard library only. The game itself is a Rojo project:
// `rojo build default.project.json --output game.rbxl` turns src/ into
// the binary place, and this program hands that place in. It copies the
// place, the scripts, the screenshots and the play link from beside this
// file into /output, then writes /output/dossier.json — the summary the
// judge reads — with the vendored make.fun library.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for
// /output, so a local run looks like this:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

function copyInto(name: string): void {
  const from = join(here, name);
  const to = join(out, name);
  if (!existsSync(from)) throw new Error(`Starfall Rush: missing ${name} beside main.ts`);
  copyFileSync(from, to);
}

mkdirSync(out, { recursive: true });

// The binary place and the play link go in as single files.
copyInto('game.rbxl');
copyInto('PLAY.json');

// Every script of the place, as .luau files under src/, in full.
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true });

// The start, play and end screens; the first by name is the cover.
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true });
}

// The dossier, with the scorer's own caps: the text is cut at 64 KiB,
// at most 4 screenshots of at most 256 KiB each, a place of at most
// 500,000 instances, scripts of at most 8 MiB of source in all, and
// script paths of at most 1,048,576 characters in all.
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
