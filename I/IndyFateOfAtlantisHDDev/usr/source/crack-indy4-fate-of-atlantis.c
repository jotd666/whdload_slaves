/* Fuck, so many years after I tried to crack this Indy4 game
 * (Indiana Jones and the Fate of Atlantis), here is a crack!
 *
 * Problem is: I used ScummVM, their disassembler, and some hand-made
 * tools to extract scripts from datafiles.
 * So not a "real" crack. I didn't struggle hard.
 * But I guess I couldn't have done it fifteen years ago, simply because
 * I didn't have the right knowledge. I breakpointed the whole
 * interpreter, trying to modify jumps here and there, with no
 * success.
 * I didn't know the program was just an interpreter.
 * I didn't know I had to understand opcodes.
 * I didn't know I had to decypher the datafile's format.
 * I didn't know anything.
 *
 * Even today, without ScummVM, the sources and the website, I couldn't
 * have done it.
 *
 * So it's just a lame crack.
 * Extract the scripts, dig for the correct room, find the code where
 * the test is done, and change a few bits here and there.
 *
 * In a way, there is nothing to be proud of.
 *
 * But I am.
 * Because this game resisted all my poor attempts to fuck it.
 * Period.
 * 2010-03-31
 * http://sed.free.fr
 */

#include <stdio.h>
#include <string.h>

char buf[4096+7*3];

int main(int n, char **v)
{
  /* we look for:
   * c8 f4 00 d3 00 19 00 c8 f5 00 d4 00 12 00 c8 f6 00 d5 00 0b 00
   * which corresponds to:
   *     [0040] (C8)     if (Var[244] == Var[211]) {
   *     [0047] (C8)       if (Var[245] == Var[212]) {
   *     [004E] (C8)         if (Var[246] == Var[213]) {
   * and replace 211 by 244, 212 by 245 and 213 by 246
   * so that the test passes whatever the user sets as response
   * to the question.
   */
  char dig[] = { 0xc8, 0xf4, 0x00, 0xd3, 0x00, 0x19, 0x00,
                 0xc8, 0xf5, 0x00, 0xd4, 0x00, 0x12, 0x00,
                 0xc8, 0xf6, 0x00, 0xd5, 0x00, 0x0b, 0x00 };
  FILE *f;
  int pos;
  int i;
  long start_offset = -7*3;
  long offset;
  unsigned char rep;

  if (n != 2) {
    printf("gimme the ATLANTIS.001 file as argument, cunt of you...\n");
    return 1;
  }

  f = fopen(v[1], "r+b"); if (!f) { perror(v[1]); return 1; }

  while (1) {
    memcpy(buf, buf+4096, 7*3);
    if (fread(buf+7*3, 4096, 1, f) == 0 && feof(f)) break;
    pos = 0;
    for (i = 0; i < 4096+7*3; i++) {
      if (dig[pos] == (buf[i] ^ 0x69)) pos++; else { i -= pos; pos = 0; }
      if (pos == 7*3) goto found;
    }
    start_offset += 4096;
  }

  printf("Error. Not a real ATLANTIS.001 you gave? Contact sed@free.fr\n");
  fclose(f);
  return 1;

found:
  offset = i+1-pos + start_offset;
  printf("found at offset %ld\n", offset);
  printf("patching...\n");

  fseek(f, offset+3,     SEEK_SET); rep = 0xf4 ^ 0x69; fwrite(&rep, 1, 1, f);
  fseek(f, offset+3+7,   SEEK_SET); rep = 0xf5 ^ 0x69; fwrite(&rep, 1, 1, f);
  fseek(f, offset+3+7+7, SEEK_SET); rep = 0xf6 ^ 0x69; fwrite(&rep, 1, 1, f);

  printf("done.\nhttp://sed.free.fr for more shit!\n");
  fclose(f);
  return 0;
}
