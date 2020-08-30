#include <stdio.h>

#if 0
#include <stat.h>

int get_size(const char *fname)
{
  int rval = 0;
  struct stat buf;
 
  if (stat(fname,&buf)==0)
  {
    rval = buf.st_size;
  }

  return rval;
}
#endif

int main(unsigned int argc, const char **argv)
{

  FILE *f1;
  FILE *f2,*f3;
  int nb_items1,nb_items2;
  char c;

  if (argc!=4) {fprintf(stderr,"Usage: datmerger <file1> <file2> <output>\n");return 1;}

  f1 = fopen(argv[1],"rb");
  if (f1==NULL) {fprintf(stderr,"Can't open file %s\n",argv[1]);return 2;}
  f2 = fopen(argv[2],"rb");
  if (f2==NULL) {fclose(f1);fprintf(stderr,"Can't open file %s\n",argv[2]);return 2;}

  f3 = fopen(argv[3],"wb");
  if (f3==NULL) {fclose(f1);fclose(f2);fprintf(stderr,"Can't create file %s\n",argv[3]);return 2;}
 
  fgetc(f1);
  fgetc(f2);

  nb_items1 = fgetc(f1);
  nb_items2 = fgetc(f2);

  fputc(0,f3);
  fputc((char)(nb_items1+nb_items2),f3);

  while(!feof(f1))
  {
  
    c = fgetc(f1);

    if (c!=0xff)
    {
      fputc(c,f3);
    }
  }
  while(!feof(f2))
  {
    c= fgetc(f2);

    if (c!=0xff)
    {
      fputc(c,f3);
    }
  }
 fputc(0xff,f3);

  fclose(f1);
  fclose(f2);
  fclose(f3);

  return 0;
}

