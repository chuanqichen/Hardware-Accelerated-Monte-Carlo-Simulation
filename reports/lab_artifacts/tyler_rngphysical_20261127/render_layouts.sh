#!/usr/bin/env bash
set -euo pipefail
cd /home/work/teh969/mc_rngphysical_20261127
module load cadence/2022
session=build/tyler_rng_20261127
trap 'rc=$?; printf "exit_code=%s\n" "$rc" > "$session/render.exit"' EXIT
for lanes in 1 2 4; do
  tag=tyler_rng_closure_20261127_l${lanes}
  [[ "$lanes" != 2 ]] || tag=${tag}_hold2
  PNR_DB="$PWD/reports/pnr/$tag/mc_top.enc.dat" PNR_IMAGE="$PWD/$session/rng_lookahead_l${lanes}.gif" \
    xvfb-run -a -s '-screen 0 1800x1200x24' innovus -files scripts/pnr/render.tcl > "$session/render_l${lanes}.log" 2>&1
  grep -q '^LAYOUT_IMAGE_DONE ' "$session/render_l${lanes}.log"
done
/home/work/teh969/pyenv/mc_py312/bin/python - <<'PY'
from pathlib import Path
from PIL import Image
for lanes in (1, 2, 4):
    source = Path(f'build/tyler_rng_20261127/rng_lookahead_l{lanes}.gif')
    target = Path(f'docs/figures/rng_lookahead_l{lanes}.png')
    assert not target.exists(), target
    with Image.open(source) as img:
        img.save(target)
        with Image.open(target) as exported:
            assert img.convert('RGBA').tobytes() == exported.convert('RGBA').tobytes()
            assert img.size == exported.size
    print('LOSSLESS_LAYOUT_EXPORT', target)
PY
echo LAYOUTS_COMPLETE
