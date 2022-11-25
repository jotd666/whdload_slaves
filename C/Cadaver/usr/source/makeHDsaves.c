#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include <dos/dos.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <exec/execbase.h>
#include <exec/memory.h>
#include <pragmas/dos_pragmas.h>
#include <string.h>

extern struct ExecBase *SysBase;

extern ULONG InitTrackDisk(ULONG);
extern void ShutTrackDisk(void);
extern void ReadTrack(ULONG,APTR);
extern ULONG CheckDiskIn (void);
extern void ReadSector(ULONG,APTR);

APTR trackBuffer=0L;
FILE *f=0L;
int diskinit=0,allocated=0;
ULONG diskunit;
char *charunit="DFx:";

void CloseAll(int);

void ControlC(int code)

{
  signal(SIGINT,SIG_IGN);

  printf("** Break\n");
  CloseAll(code);
}

void CloseAll(int code)

{
if (allocated) Inhibit(charunit,FALSE);
if (diskinit) ShutTrackDisk();
if (trackBuffer) FreeMem(trackBuffer,512);
if (f) fclose(f);
exit(0);
}


main(unsigned int argc,char ** argv)


{
  ULONG i;
  int savetype,tk_offset;
  char c,d,filename[20];
  char stchar[]={'o','p'};

  signal(SIGINT,ControlC);

  printf("Cadaver HD save maker.\nProgrammed by Jean-François Fabre © 1997.\n\nWhich save do you want to convert?\n\n  1) Original\n  2) The payoff\n\n");

 do
  {
  fflush(stdin);
  printf("? ");
  fflush(stdout);
  c=getchar();
  }
 while(c!='1'&&c!='2');

  savetype=stchar[c-'1'];

  printf("\n\nWhich position do you want to rip (0-9) ?\n");

 do
  {
  fflush(stdin);
  printf("? ");
  fflush(stdout);
  c=getchar();
  }
 while(c<'0'||c>'9');

  printf("\n\nWhich disk unit do you want to use (0-3) ?\n");

 do
  {
  fflush(stdin);
  printf("? ");
  fflush(stdout);
  d=getchar();
  }
 while(d<'0'||d>'3');

  diskunit=d-'0';

  sprintf(filename,"saves/savegame_%c.%c",savetype,c);

  charunit[2]=diskunit+'0';

  if (SysBase->LibNode.lib_Version>36)
    {
    if (Inhibit(charunit,DOSTRUE)==FALSE) {printf("** Can't allocate device !");CloseAll(0);}
    allocated=1;
    }

  if (c=='0') tk_offset=0x6E*10; else tk_offset=0x6E*(c-'1');

  if (InitTrackDisk(diskunit)<0) {printf("** Can't open unit %d !",diskunit);CloseAll(0);}
  diskinit=1;
  if (CheckDiskIn()) {printf("** No disk in DF%d: !\n",diskunit);CloseAll(0);}

  f=fopen(filename,"wb");

  if (f==0L) {printf("** Can't create file !\n");CloseAll(0);}

  trackBuffer=AllocMem(512,MEMF_CHIP|MEMF_CLEAR);  
  if (trackBuffer==0L) {printf("** Can't allocate memory.\n");CloseAll(0);}

  for (i=0;i<0x6E;i++)
   {
    ReadSector(tk_offset+i,trackBuffer);
    if (fwrite(trackBuffer,1,512,f)!=512) {printf("** Disk full !");break;}
   }

  CloseAll(0);
}
