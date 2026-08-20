"""
Generate obfuscated bytes for the MiniMax API key.
XOR with a fixed 8-byte key. Run this once and paste output into wish_service.dart.
"""
KEY = "sk-cp-ZT7anHU_uPe4MJlPBxHFcg5xWy0qEFBKVR0HbsFdFJe4TO2S0JkFGIi4Yv4ygADCufOH9PV82z5SY_u5pa4UWTl5pJDnG20qLAryDYDZhyKiUiLMDbI16PA"
OBF_KEY = [0x4A, 0x7B, 0x33, 0xC1, 0x9F, 0x12, 0x6E, 0x58]

# Verify roundtrip
obf = [ord(c) ^ OBF_KEY[i % len(OBF_KEY)] for i, c in enumerate(KEY)]
back = ''.join(chr(b ^ OBF_KEY[i % len(OBF_KEY)]) for i, b in enumerate(obf))
print(f"Original:  {KEY}")
print(f"Decoded:   {back}")
print(f"Match: {back == KEY}")
print()
print("Bytes for wish_service.dart:")
print("static const List<int> _obf = <int>[")
# Print 8 per line
for i in range(0, len(obf), 8):
    chunk = obf[i:i+8]
    print("    " + ", ".join(f"0x{b:02X}" for b in chunk) + ",")
print("];")
