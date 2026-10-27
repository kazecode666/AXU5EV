/* Host validation of the same runner + Cortex-R generated source. Not ARM_RUN. */
#include "replay_runner.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc,char **argv)
{
    FILE *stream;
    double *input,*output;
    unsigned long frames;
    Ax02aResult result;
    if(argc!=4) {fprintf(stderr,"usage: host_replay input.bin frames output.bin\n");return 2;}
    frames=strtoul(argv[2],NULL,10);
    if(!frames||frames>65536) return 2;
    input=malloc(frames*20*sizeof(double));output=malloc(frames*41*sizeof(double));
    if(!input||!output) return 2;
    stream=fopen(argv[1],"rb");if(!stream)return 2;
    if(fread(input,20*sizeof(double),frames,stream)!=frames||fgetc(stream)!=EOF)return 2;
    fclose(stream);
    result=ax02a_replay(input,output,NULL,(uint32_t)frames,NULL);
    if(result.status||result.completed_frames!=frames)return 1;
    stream=fopen(argv[3],"wb");if(!stream)return 2;
    if(fwrite(output,41*sizeof(double),frames,stream)!=frames)return 2;
    if(fclose(stream))return 2;
    free(input);free(output);
    puts("HOST_REPLAY_PASS (not ARM execution)");return 0;
}
