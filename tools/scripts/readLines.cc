#include <iostream>
#include <fstream>
#include <string>
using namespace std;

int main () {
  string line;
  ifstream inFile;
  char  inFilePath[] = "/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/.inductorGuide.csv";  
  inFile.open(inFilePath);
  while ( !inFile.eof() )
  {
    getline (inFile,line);
    cout << line << endl;
  }
  inFile.close();
  cout << "hola\n";
}
