#!/usr/bin/env python3
"""
patch_item_random_suffix.py
────────────────────────────────────────────────────────────────────────────
Appends four custom tier-tag suffix rows to ItemRandomSuffix.dbc.

Works with ANY field count — reads the layout from the DBC header
instead of assuming the vanilla WotLK 21-field structure. This handles
repacks and custom servers that have already modified the DBC.

Usage
-----
  python patch_item_random_suffix.py ItemRandomSuffix.dbc

The input file is modified in-place. A .bak backup is created automatically.

Steps
-----
  1. Extract ItemRandomSuffix.dbc from your highest-numbered client MPQ
     using Ladik's MPQ Editor (free at zezula.net).
     Path inside MPQ:  DBFilesClient/ItemRandomSuffix.dbc
  2. Drop the extracted file next to this script.
  3. Run:  python patch_item_random_suffix.py ItemRandomSuffix.dbc
  4. Add the patched DBC to Data/patch-A.MPQ under the same path.
  5. Restart the WoW client.

Added suffix IDs
----------------
  9901  SynHeroic
  9902  Mythical
  9903  Ascended
  9904  Synival's Chosen
"""

import struct
import sys
import os
import shutil

WDBC_MAGIC = b'WDBC'

CUSTOM_SUFFIXES = [
    (9901, "SynHeroic"),
    (9902, "Mythical"),
    (9903, "Ascended"),
    (9904, "Synival's Chosen"),
]


def read_dbc(path):
    with open(path, 'rb') as f:
        data = f.read()

    if data[:4] != WDBC_MAGIC:
        raise ValueError(f"Not a WDBC file: got magic {data[:4]!r}")

    num_records, num_fields, rec_size, str_blk_size = struct.unpack_from('<4I', data, 4)
    print(f"  Records    : {num_records}")
    print(f"  Fields     : {num_fields}")
    print(f"  Record size: {rec_size} bytes")
    print(f"  String blk : {str_blk_size} bytes")

    if rec_size != num_fields * 4:
        raise ValueError(
            f"Record size {rec_size} is not fields*4 ({num_fields * 4}). "
            "File may be corrupt."
        )

    hdr_end   = 20
    recs_end  = hdr_end + num_records * rec_size
    str_block = data[recs_end : recs_end + str_blk_size]

    records = []
    fmt = f'<{num_fields}I'
    for i in range(num_records):
        off = hdr_end + i * rec_size
        records.append(list(struct.unpack_from(fmt, data, off)))

    return num_fields, rec_size, records, str_block


def get_str(block, offset):
    """Read a null-terminated UTF-8 string from the string block."""
    if offset == 0:
        return ""
    try:
        end = block.index(b'\x00', offset)
        return block[offset:end].decode('utf-8', errors='replace')
    except ValueError:
        return ""


def find_name_fields(records, str_block, num_fields):
    """
    Auto-detect which field holds the enUS display name and which holds
    the internal name by scanning existing records for non-zero string offsets
    that resolve to printable text.

    ItemRandomSuffix layout (any field count):
      Field 0:  ID (uint32)
      Field 1:  name_enUS string offset  <- we want this
      Fields 2..N-2: other locale offsets + flags
      Field N-1 or nearby: InternalName string offset

    Strategy: field 1 is always the enUS name in all known WotLK DBC variants.
    The internal name is the last string-ref field before the enchant/alloc data.
    We detect it by scanning backwards from the end for a field that points to
    a non-empty string in the string block.
    """
    str_blk_size = len(str_block)

    # Field 1 is reliably enUS name in all WotLK ItemRandomSuffix variants
    f_name_enus = 1

    # Scan backwards to find the internal name field
    # It is typically around field 10 in vanilla (21-field) or field 18 in
    # 29-field variants, but we detect it rather than hardcode.
    f_internal = None

    # Sample first 10 records to find consistent string-like fields
    sample = records[:min(10, len(records))]

    # For each field (starting from field 1 backwards from mid-point),
    # check how many samples resolve to non-empty printable strings
    candidates = []
    for f in range(1, num_fields):
        hits = 0
        for rec in sample:
            val = rec[f]
            if 0 < val < str_blk_size:
                s = get_str(str_block, val)
                if s and all(0x20 <= ord(c) <= 0x7E or c in "'\u2019" for c in s):
                    hits += 1
        if hits >= max(1, len(sample) // 2):
            candidates.append(f)

    # The last candidate before the numeric-only fields is the internal name
    if len(candidates) >= 2:
        f_internal = candidates[-1]
    elif len(candidates) == 1:
        f_internal = candidates[0]
    else:
        # Fallback: use field 1 for both (display name only, no internal)
        f_internal = f_name_enus

    print(f"  Detected enUS name field : {f_name_enus}")
    print(f"  Detected internal name field: {f_internal}")
    return f_name_enus, f_internal


def append_strings(block, strings):
    """Append strings to block. Returns (new_block, list_of_offsets)."""
    buf = bytearray(block)
    offsets = []
    for s in strings:
        offsets.append(len(buf))
        buf.extend(s.encode('utf-8'))
        buf.append(0)
    return bytes(buf), offsets


def write_dbc(path, num_fields, records, str_block):
    rec_size = num_fields * 4
    hdr = struct.pack('<4s4I',
        WDBC_MAGIC,
        len(records),
        num_fields,
        rec_size,
        len(str_block),
    )
    fmt = f'<{num_fields}I'
    rec_data = bytearray()
    for fields in records:
        rec_data.extend(struct.pack(fmt, *fields))
    with open(path, 'wb') as f:
        f.write(hdr)
        f.write(rec_data)
        f.write(str_block)
    total = 20 + len(rec_data) + len(str_block)
    print(f"\nPatched DBC written: {path}")
    print(f"  Total records: {len(records)}")
    print(f"  File size    : {total} bytes")


def patch(path):
    print(f"\nReading: {path}")
    num_fields, rec_size, records, str_block = read_dbc(path)

    # Check for ID conflicts
    existing = {r[0] for r in records}
    conflicts = [sid for sid, _ in CUSTOM_SUFFIXES if sid in existing]
    if conflicts:
        print(f"\nERROR: IDs {conflicts} already exist in the DBC.")
        print("Restore ItemRandomSuffix.dbc.bak and run again.")
        sys.exit(1)

    # Show last 3 existing entries for sanity check
    f_name, f_internal = find_name_fields(records, str_block, num_fields)
    print("\nLast 3 existing entries:")
    for r in records[-3:]:
        print(f"  ID={r[0]:6d}  '{get_str(str_block, r[f_name])}'")

    # Append our display name + internal name strings
    new_strings = []
    for _, name in CUSTOM_SUFFIXES:
        new_strings.append(name)  # display (enUS)
        new_strings.append(name)  # internal
    new_str_block, offsets = append_strings(str_block, new_strings)

    # Build new rows — same width as existing records, all zeros except
    # ID, enUS name offset, locale flags (enUS = 0x04), internal name offset.
    #
    # Locale flag field: in vanilla it is field 9 (after 8 locale string refs).
    # In a 29-field variant there are 16 locale string refs before the flag.
    # We set ALL string-ref-looking fields (fields 1 .. f_internal) to point
    # to our enUS string — clients that support other locales will just see the
    # same text, which is fine for custom suffixes.
    print("\nInjecting rows:")
    for i, (sid, name) in enumerate(CUSTOM_SUFFIXES):
        disp_off = offsets[i * 2]
        int_off  = offsets[i * 2 + 1]

        row = [0] * num_fields
        row[0]          = sid       # ID
        row[f_name]     = disp_off  # enUS display name
        row[f_internal] = int_off   # internal name

        # Fill all intermediate locale string fields with the same offset
        # so no locale shows a blank name
        for f in range(1, f_internal):
            if row[f] == 0:         # don't overwrite if already set
                row[f] = disp_off

        # Set locale flags field (field after last locale string ref)
        # 0x7FFFFFFF = all locales present
        flag_field = f_internal + 1
        if flag_field < num_fields:
            row[flag_field] = 0x7FFFFFFF

        records.append(row)
        print(f"  ID={sid}  str_offset={disp_off:5d}  '{name}'")

    write_dbc(path, num_fields, records, new_str_block)
    print("\nDone. Add the patched DBC to your custom patch MPQ under:")
    print("  DBFilesClient/ItemRandomSuffix.dbc")


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} <ItemRandomSuffix.dbc>")
        sys.exit(1)

    target = sys.argv[1]
    if not os.path.isfile(target):
        print(f"File not found: {target}")
        sys.exit(1)

    bak = target + '.bak'
    if not os.path.exists(bak):
        shutil.copy2(target, bak)
        print(f"Backup: {bak}")
    else:
        print(f"Backup already present: {bak}")

    patch(target)
