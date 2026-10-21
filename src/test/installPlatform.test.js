import { describe, it, expect } from 'vitest';
import { detectPlatform } from '../components/InstallAnywhere';

describe('detectPlatform', () => {
  it('reads the visitor platform from the user agent', () => {
    expect(detectPlatform('Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)', true)).toBe('ios');
    expect(detectPlatform('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', true)).toBe('ios'); // iPadOS
    expect(detectPlatform('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', false)).toBe('mac');
    expect(detectPlatform('Mozilla/5.0 (Linux; Android 15; Pixel 9)', true)).toBe('android');
    expect(detectPlatform('Mozilla/5.0 (Windows NT 10.0; Win64; x64)', false)).toBe('windows');
    expect(detectPlatform('Mozilla/5.0 (X11; Linux x86_64)', false)).toBe('linux');
    expect(detectPlatform('curl/8', false)).toBe('web');
  });
});
