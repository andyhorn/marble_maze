import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Regenerates the toy-marble base-colour texture bundled at
/// `assets/textures/marble_swirl.png`.
///
/// A classic toy marble is glass or clay with a swirl of colour baked in, so
/// its rotation as it rolls is obvious, unlike a flat or mirror-metal
/// sphere. This paints a 512x256 equirectangular map (matching
/// `SphereGeometry`'s UVs) with three colours blended along a swirl that
/// varies with latitude, using only integer-frequency functions of longitude
/// so the left and right edges (u=0 and u=1) match exactly and the sphere
/// shows no seam.
///
/// No image-decoding package is a dependency of `level_presentation`, so
/// this writes raw PNG chunks by hand, deflating scanlines with
/// `dart:io`'s `ZLibEncoder` and computing each chunk's CRC32 itself.
///
/// Run with `dart run tool/generate_marble_texture.dart` from
/// `features/level/level_presentation/`.
void main() {
  const width = 512;
  const height = 256;
  final pixels = Uint8List(width * height * 3);

  const cream = (0xF2, 0xE9, 0xD8);
  const swirlA = (0xB5, 0x65, 0x1D); // amber-brown
  const swirlB = (0x7A, 0x1F, 0x1A); // deep red-brown

  for (var y = 0; y < height; y++) {
    final v = y / (height - 1);
    // Latitude in [-pi/2, pi/2]; bands of swirl frequency vary with it so
    // the pattern reads as a twisted rope rather than plain horizontal
    // stripes.
    final latitude = (v - 0.5) * math.pi;
    for (var x = 0; x < width; x++) {
      final u = x / width;
      final longitude = u * 2 * math.pi;

      // Two integer-frequency swirl waves, offset in phase by latitude, so
      // the bands twist as they wrap from pole to pole while staying
      // perfectly periodic in longitude (no seam at u=0/1).
      final wave1 = math.sin(3 * longitude + latitude * 4);
      final wave2 = math.sin(5 * longitude - latitude * 2);
      final swirl = (wave1 + wave2) / 2;

      final (int r, int g, int b) color;
      if (swirl > 0.5) {
        color = (swirlA.$1, swirlA.$2, swirlA.$3);
      } else if (swirl < -0.5) {
        color = (swirlB.$1, swirlB.$2, swirlB.$3);
      } else {
        color = cream;
      }

      final offset = (y * width + x) * 3;
      pixels[offset] = color.$1;
      pixels[offset + 1] = color.$2;
      pixels[offset + 2] = color.$3;
    }
  }

  final png = _encodePng(width: width, height: height, rgb: pixels);
  final outFile = File('assets/textures/marble_swirl.png')
    ..writeAsBytesSync(png);
  stdout.writeln('Wrote ${outFile.path} (${png.length} bytes)');
}

/// Encodes raw 8-bit RGB [rgb] pixel data (row-major, no padding) as a
/// minimal PNG: signature, `IHDR`, one `IDAT` holding all scanlines
/// (each prefixed with filter type 0, "none"), and `IEND`.
Uint8List _encodePng({
  required int width,
  required int height,
  required Uint8List rgb,
}) {
  const bytesPerPixel = 3;
  final stride = width * bytesPerPixel;
  final raw = Uint8List(height * (stride + 1));
  for (var y = 0; y < height; y++) {
    final srcStart = y * stride;
    final dstStart = y * (stride + 1);
    raw[dstStart] = 0; // filter type: none
    raw.setRange(dstStart + 1, dstStart + 1 + stride, rgb, srcStart);
  }

  final deflated = ZLibEncoder().convert(raw);

  final ihdr = BytesBuilder()
    ..add(_beUint32(width))
    ..add(_beUint32(height))
    ..addByte(8) // bit depth
    ..addByte(2) // colour type: RGB (truecolour, no alpha)
    ..addByte(0) // compression method: deflate
    ..addByte(0) // filter method: adaptive (per-scanline filter byte above)
    ..addByte(0); // interlace method: none

  final builder = BytesBuilder()
    ..add(const [137, 80, 78, 71, 13, 10, 26, 10]) // PNG signature
    ..add(_chunk('IHDR', ihdr.toBytes()))
    ..add(_chunk('IDAT', Uint8List.fromList(deflated)))
    ..add(_chunk('IEND', Uint8List(0)));
  return builder.toBytes();
}

Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final builder = BytesBuilder()
    ..add(_beUint32(data.length))
    ..add(typeBytes)
    ..add(data)
    ..add(_beUint32(_crc32(Uint8List.fromList(typeBytes + data))));
  return builder.toBytes();
}

Uint8List _beUint32(int value) => Uint8List(4)
  ..[0] = (value >> 24) & 0xFF
  ..[1] = (value >> 16) & 0xFF
  ..[2] = (value >> 8) & 0xFF
  ..[3] = value & 0xFF;

final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
    table[n] = c;
  }
  return table;
}

int _crc32(Uint8List bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
