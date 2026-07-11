#!/usr/bin/env python3
"""Gera um tema de cursor XCursor 100% transparente ('blank')."""
import os
import struct

HOME = os.path.expanduser("~")
THEME_DIR = os.path.join(HOME, ".local/share/icons/blank")
CURSORS_DIR = os.path.join(THEME_DIR, "cursors")
BREEZE = "/usr/share/icons/breeze_cursors/cursors"

IMAGE_TYPE = 0xFFFD0002


def image_chunk(size):
    w = h = size
    xhot = yhot = 0
    delay = 0
    pixels = b"\x00\x00\x00\x00" * (w * h)  # ARGB todo zero = transparente
    hdr = struct.pack("<IIII", 36, IMAGE_TYPE, size, 1)
    imghdr = struct.pack("<IIIII", w, h, xhot, yhot, delay)
    return hdr + imghdr + pixels


def build_cursor():
    sizes = [24, 32, 48, 64]
    chunks = [image_chunk(s) for s in sizes]
    fileheader = b"Xcur" + struct.pack("<III", 16, 0x00010000, len(sizes))
    toc_size = 12 * len(sizes)
    offset = len(fileheader) + toc_size
    toc = b""
    for s, ch in zip(sizes, chunks):
        toc += struct.pack("<III", IMAGE_TYPE, s, offset)
        offset += len(ch)
    return fileheader + toc + b"".join(chunks)


def main():
    os.makedirs(CURSORS_DIR, exist_ok=True)
    cur = build_cursor()

    base = os.path.join(CURSORS_DIR, "left_ptr")
    with open(base, "wb") as f:
        f.write(cur)

    # Cobre TODOS os nomes de cursor que o Breeze define, apontando pro transparente.
    names = set()
    if os.path.isdir(BREEZE):
        names.update(os.listdir(BREEZE))
    # garante os essenciais mesmo sem o Breeze
    names.update([
        "default", "left_ptr", "arrow", "top_left_arrow", "pointer",
        "hand", "hand1", "hand2", "text", "xterm", "ibeam", "wait",
        "watch", "progress", "crosshair", "help", "question_arrow",
    ])
    made = 0
    for n in names:
        if n == "left_ptr":
            continue
        dst = os.path.join(CURSORS_DIR, n)
        try:
            if os.path.lexists(dst):
                os.remove(dst)
            os.symlink("left_ptr", dst)
            made += 1
        except OSError as e:
            print("skip", n, e)

    with open(os.path.join(THEME_DIR, "index.theme"), "w") as f:
        f.write(
            "[Icon Theme]\n"
            "Name=blank\n"
            "Comment=Cursor totalmente transparente (console/Big Picture)\n"
        )

    print(f"Tema 'blank' criado em {THEME_DIR}")
    print(f"left_ptr = {len(cur)} bytes, {made} symlinks de nomes de cursor")


if __name__ == "__main__":
    main()
