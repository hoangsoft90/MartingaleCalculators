import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

/// Simple PNG icon generator for Grid Survival Simulator
/// Generates solid color icons with basic shapes

void main() {
  final sizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final density = entry.key;
    final size = entry.value;
    final dir = Directory('mipmap-$density');
    
    // Create simple solid color PNG
    final png = createSimpleIcon(size);
    
    File('${dir.path}/ic_launcher.png').writeAsBytesSync(png);
    File('${dir.path}/ic_launcher_round.png').writeAsBytesSync(png);
    
    print('Created $density ($size x $size)');
  }
  
  print('✅ Icons generated!');
}

/// Create a simple PNG with solid color (dark blue with green accent)
Uint8List createSimpleIcon(int size) {
  // PNG signature
  final signature = [137, 80, 78, 71, 13, 10, 26, 10];
  
  // IHDR chunk
  final ihdr = createIHDR(size, size);
  
  // IDAT chunk (image data)
  final idat = createIDAT(size);
  
  // IEND chunk
  final iend = [0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];
  
  // Combine all chunks
  final bytes = <int>[];
  bytes.addAll(signature);
  bytes.addAll(ihdr);
  bytes.addAll(idat);
  bytes.addAll(iend);
  
  return Uint8List.fromList(bytes);
}

/// Create IHDR chunk
List<int> createIHDR(int width, int height) {
  final data = <int>[
    0, 0, 0, 13, // Length
    73, 72, 68, 82, // IHDR
    (width >> 24) & 0xFF,
    (width >> 16) & 0xFF,
    (width >> 8) & 0xFF,
    width & 0xFF,
    (height >> 24) & 0xFF,
    (height >> 16) & 0xFF,
    (height >> 8) & 0xFF,
    height & 0xFF,
    8, // Bit depth
    2, // Color type (RGB)
    0, // Compression
    0, // Filter
    0, // Interlace
  ];
  
  // Calculate CRC
  final crc = calculateCRC(data.sublist(4));
  data.addAll(crc);
  
  return data;
}

/// Create IDAT chunk with image data
List<int> createIDAT(int size) {
  final rawData = <int>[];
  
  // Create image with dark blue background and green chart elements
  for (int y = 0; y < size; y++) {
    rawData.add(0); // Filter byte (none)
    
    for (int x = 0; x < size; x++) {
      // Background color: dark navy blue (#0D1B2A)
      int r = 13, g = 27, b = 42;
      
      // Add subtle grid pattern
      if (x % (size ~/ 6) == 0 || y % (size ~/ 6) == 0) {
        r = 30; g = 58; b = 95; // #1E3A5F
      }
      
      // Add chart area (green bars)
      final centerX = size ~/ 2;
      final centerY = size ~/ 2;
      
      // Bar 1 (left)
      if (x > size * 0.2 && x < size * 0.35 && 
          y > size * 0.3 && y < size * 0.7) {
        r = 76; g = 175; b = 80; // #4CAF50
      }
      
      // Bar 2 (middle-left, red)
      if (x > size * 0.38 && x < size * 0.52 && 
          y > size * 0.4 && y < size * 0.8) {
        r = 244; g = 67; b = 54; // #F44336
      }
      
      // Bar 3 (middle-right)
      if (x > size * 0.55 && x < size * 0.7 && 
          y > size * 0.25 && y < size * 0.65) {
        r = 76; g = 175; b = 80; // #4CAF50
      }
      
      // Trend line (gold)
      final lineY = size * 0.7 - (x - size * 0.2) * 0.5;
      if (x > size * 0.2 && x < size * 0.8 && 
          (y - lineY).abs() < 2) {
        r = 255; g = 215; b = 0; // #FFD700
      }
      
      rawData.addAll([r, g, b]);
    }
  }
  
  // Compress with zlib (simple store, no compression for small images)
  final compressed = zlibEncode(Uint8List.fromList(rawData));
  
  final chunk = <int>[
    (compressed.length >> 24) & 0xFF,
    (compressed.length >> 16) & 0xFF,
    (compressed.length >> 8) & 0xFF,
    compressed.length & 0xFF,
    73, 68, 65, 84, // IDAT
  ];
  chunk.addAll(compressed);
  
  // Calculate CRC
  final crc = calculateCRC(chunk.sublist(4));
  chunk.addAll(crc);
  
  return chunk;
}

/// Simple zlib encode (store only, no compression)
Uint8List zlibEncode(Uint8List data) {
  final result = <int>[];
  result.addAll([0x78, 0x01]); // zlib header (no compression)
  
  // Split into blocks of 65535 bytes
  int offset = 0;
  while (offset < data.length) {
    final blockLength = min(65535, data.length - offset);
    final isLast = (offset + blockLength >= data.length);
    
    // Block header
    result.add(isLast ? 0x01 : 0x00);
    result.add(blockLength & 0xFF);
    result.add((blockLength >> 8) & 0xFF);
    result.add((~blockLength) & 0xFF);
    result.add((~blockLength >> 8) & 0xFF);
    
    // Block data
    result.addAll(data.sublist(offset, offset + blockLength));
    
    offset += blockLength;
  }
  
  // Adler32 checksum
  final adler = adler32(data);
  result.add((adler >> 24) & 0xFF);
  result.add((adler >> 16) & 0xFF);
  result.add((adler >> 8) & 0xFF);
  result.add(adler & 0xFF);
  
  return Uint8List.fromList(result);
}

/// Calculate Adler32 checksum
int adler32(Uint8List data) {
  int a = 1, b = 0;
  for (final byte in data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  return (b << 16) | a;
}

/// Calculate CRC32
List<int> calculateCRC(List<int> data) {
  int crc = 0xFFFFFFFF;
  
  for (final byte in data) {
    crc ^= byte;
    for (int j = 0; j < 8; j++) {
      if ((crc & 1) == 1) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  
  crc ^= 0xFFFFFFFF;
  
  return [
    (crc >> 24) & 0xFF,
    (crc >> 16) & 0xFF,
    (crc >> 8) & 0xFF,
    crc & 0xFF,
  ];
}
