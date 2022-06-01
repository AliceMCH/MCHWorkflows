#include <stdio.h>
#include <string>
#include <fstream>


int main(int argc, char** argv)
{
  std::string content;
  std::string s;
  std::ifstream in(argv[1]);
  while (std::getline(in, s)) {
    int solar, cru, l;
    int n = sscanf(s.c_str(), "%d %d %d", &solar, &cru, &l);
    if (n == 3) {
      int f = cru * 2;
      if (l > 11) {
	f += 1;
	l -= 12;
      }
      printf("%d\t%d\t%d\n", solar, f, l);
    }
  }
}
