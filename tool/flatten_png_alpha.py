#!/usr/bin/env python3
import struct
import sys
import zlib


PNG_SIG = b"\x89PNG\r\n\x1a\n"


def read_chunks(data):
    if not data.startswith(PNG_SIG):
        raise ValueError("not a PNG")
    pos = len(PNG_SIG)
    while pos < len(data):
        size = struct.unpack(">I", data[pos : pos + 4])[0]
        kind = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + size]
        yield kind, chunk
        pos += 12 + size


def paeth(a, b, c):
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def unfilter(raw, width, height, bpp):
    stride = width * bpp
    rows = []
    pos = 0
    prev = bytearray(stride)
    for _ in range(height):
        filt = raw[pos]
        pos += 1
        cur = bytearray(raw[pos : pos + stride])
        pos += stride
        for i in range(stride):
            left = cur[i - bpp] if i >= bpp else 0
            up = prev[i]
            upper_left = prev[i - bpp] if i >= bpp else 0
            if filt == 1:
                cur[i] = (cur[i] + left) & 0xFF
            elif filt == 2:
                cur[i] = (cur[i] + up) & 0xFF
            elif filt == 3:
                cur[i] = (cur[i] + ((left + up) // 2)) & 0xFF
            elif filt == 4:
                cur[i] = (cur[i] + paeth(left, up, upper_left)) & 0xFF
            elif filt != 0:
                raise ValueError(f"unsupported PNG filter {filt}")
        rows.append(bytes(cur))
        prev = cur
    return rows


def chunk(kind, payload):
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def flatten_rgba_to_black(src, dst):
    data = open(src, "rb").read()
    width = height = bit_depth = color_type = None
    compressed = []

    for kind, payload in read_chunks(data):
        if kind == b"IHDR":
            width, height, bit_depth, color_type, comp, filt, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
            if (bit_depth, color_type, comp, filt, interlace) != (8, 6, 0, 0, 0):
                raise ValueError("only non-interlaced 8-bit RGBA PNGs are supported")
        elif kind == b"IDAT":
            compressed.append(payload)

    rows = unfilter(zlib.decompress(b"".join(compressed)), width, height, 4)
    out_rows = []
    for row in rows:
        rgb = bytearray()
        for i in range(0, len(row), 4):
            r, g, b, a = row[i : i + 4]
            rgb.extend(((r * a) // 255, (g * a) // 255, (b * a) // 255))
        out_rows.append(b"\x00" + bytes(rgb))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    png = PNG_SIG + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(b"".join(out_rows), 9)) + chunk(b"IEND", b"")
    open(dst, "wb").write(png)


if __name__ == "__main__":
    flatten_rgba_to_black(sys.argv[1], sys.argv[2])
