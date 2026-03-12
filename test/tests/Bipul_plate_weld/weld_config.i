cp_file_base = '${thickness}/weld'
sync_only = True
heat_transfer_coefficient = 10e-6
delay_time = 0 #25 #300

# weld
all_blocks = 'base weld_to_base weldpass01 weldpass02 weldpass03 weldpass04 weldpass05' # weldpass-6 weldpass-7 weldpass-8'

weld_blocks = 'weldpass01 weldpass02 weldpass03 weldpass04 weldpass05' # weldpass-6 weldpass-7 weldpass-8'
subdomain_block_id = '11'
total_passes = 5 #8
base_power =  500 #40mm=500.0; 5mm=325.0
elip_a = 40
elip_b = 20
# elm_weld_time = 120
update_interval = 0
pass_weld_time = 120
total_weld_time = '${fparse pass_weld_time*total_passes + delay_time}'

# timestep restriction
dt = 0.1
dtmax = 0.5 #2.5 #2.5 #25
dtmin = 1e-8

# sync_times = '0 0.1 2.5 120 120.1 122.5 240 240.1 242.5 360 360.1 362.5 480 480.1 482.5 600'
sync_times = '0 0.1 1 2 2.5 5 15 30 45 60 75 90 105 120 120.1 122.5 125 135 150 165 180 195 210 225 240 240.1 242.5 245 255 270 285 300 315 330 345 360 360.1 362.5 365 375 390 405 420 435 450 465 480 480.1 482.5 485 495 510 525 540 555 570 585 600'

# Save residuals so that we can release load slowly later
disp_save_in = 'rx ry rz'
