#include "XorShift128Plus.c"

#include <stdio.h>
#include <stdlib.h>

int main (int argc, char *argv[])
{

  if (argc != 4) {
      printf(
        "Usage\n"
        "%s <s1> <s0> <output file>\n"
        "\n"
        "s1          - state 1 seed\n"
        "s0          - state 0 seed\n"
        "output file - File to write output words to\n",
        argv[0]);
      return 1;
  }

  s[1] = atoi(argv[1]);
  s[0] = atoi(argv[2]);

  FILE* f = fopen(argv[3], "w");

  FILE* f0 = fopen("state0.txt", "w");
  FILE* f1 = fopen("state1.txt", "w");

  for (int i=0; i<100; i++) {
    fprintf(f, "%016lx\n", next());
    fprintf(f0, "%016lx\n", s[0]);
    fprintf(f1, "%016lx\n", s[1]);
  }

  fclose(f);
  fclose(f0);
  fclose(f1);

  return 0;
}
