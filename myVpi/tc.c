#include "/usr/include/iverilog/vpi_user.h"
#include <stdio.h>
#include <time.h>


clock_t start;
clock_t stop;

static int time_compiletf(char* user_data){
    return 0;
}

void time_start(char* user_data){
    time(&start);
    vpi_printf("start measure! %d\n", start);
}

void time_stop(char* user_data){
    time(&stop);
    vpi_printf("stop measure! %d\n", stop);
}

void time_elapse(char*){
    double elapsed;
    elapsed = difftime(stop, start);
    vpi_printf("time that use is %.2f seconds\n", elapsed);

}

void timeRegister(){

    s_vpi_systf_data tf_data_start;

      tf_data_start.type      = vpiSysTask;
      tf_data_start.tfname    = "$wallClockStart";
      tf_data_start.calltf    = time_start;
      tf_data_start.compiletf = time_compiletf;
      tf_data_start.sizetf    = 0;
      tf_data_start.user_data = 0;
      vpi_register_systf(&tf_data_start);

      s_vpi_systf_data tf_data_stop;

      tf_data_stop.type      = vpiSysTask;
      tf_data_stop.tfname    = "$wallClockStop";
      tf_data_stop.calltf    = time_stop;
      tf_data_stop.compiletf = time_compiletf;
      tf_data_stop.sizetf    = 0;
      tf_data_stop.user_data = 0;
      vpi_register_systf(&tf_data_stop);

      s_vpi_systf_data tf_data_elap;

      tf_data_elap.type      = vpiSysTask;
      tf_data_elap.tfname    = "$wallClockElapse";
      tf_data_elap.calltf    = time_elapse;
      tf_data_elap.compiletf = time_compiletf;
      tf_data_elap.sizetf    = 0;
      tf_data_elap.user_data = 0;
      vpi_register_systf(&tf_data_elap);

}

void (*vlog_startup_routines[])() = {
    timeRegister,
    0
};