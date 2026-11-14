#!/usr/bin/env bash
set -u
ARCHTEST="$HOME/compliance_test/riscv-arch-test"
SIM="$HOME/compliance_test/sim/obj_dir/VSingle_CycleRV"
OUTDIR="$HOME/compliance_test/sim/results"
mkdir -p "$OUTDIR"

PASS=0; FAIL=0
for ext in I M; do
  for elf in "$ARCHTEST/work/group4-RV32IM/build/rv32i/$ext"/*.sig.elf; do
    [ -e "$elf" ] || continue
    name=$(basename "$elf" .sig.elf)
    sail_sig="$ARCHTEST/work/sail-RVI20U32/build/rv32i/$ext/${name}.sig"
    my_sig="$OUTDIR/${ext}_${name}.sig"
    syms=$(riscv-none-elf-nm "$elf")
    begin=$(echo "$syms" | awk '/ begin_signature$/{print $1}')
    end=$(echo "$syms" | awk '/ end_signature$/{print $1}')
    tohost=$(echo "$syms" | awk '/ tohost$/{print $1}')
    "$SIM" "$elf" "$my_sig" "$begin" "$end" "$tohost" 2000000 2> "$OUTDIR/${ext}_${name}.log"
    if diff -q "$sail_sig" "$my_sig" > /dev/null 2>&1; then
      echo "PASS: $ext/$name"
      ((PASS++))
    else
      echo "FAIL: $ext/$name"
      ((FAIL++))
    fi
  done
done
echo "Summary: $PASS passed, $FAIL failed"
