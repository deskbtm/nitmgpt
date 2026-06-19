String getArch(String name) {
  switch (name) {
    case 'X86_64':
      return 'x86_64';
    case 'ARM64':
      return 'arm64-v8a';
    case 'ARM':
      return 'armeabi-v7a';
    default:
      return '';
  }
}
