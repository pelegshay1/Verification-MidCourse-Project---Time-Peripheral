vlib work
vlog design/design_params_pkg.sv 
vlog -mfcu verification/timer_interface.sv \
     verification/Timertrans.sv \
     verification/derived_write_trans.sv \
     verification/derived_read_trans.sv \
     verification/TimerCoverage.sv \
     verification/TimerGenerator.sv \
     verification/TimerDriver.sv \
     verification/TimerMonitor.sv \
     verification/TimerChecker.sv \
     verification/TimerTest.sv \
     design/timer_periph.sv \
     verification/timer_assertions.sv \
 	 verification/tb_top.sv

quit -force

vlog verification/



     

     
     
     design/timer_periph.sv \
     verification/timer_assertions.sv \
     verification/tb_top.sv