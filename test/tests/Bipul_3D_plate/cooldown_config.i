cp_file_base = '${thickness}/cooldown'
sync_only = False
heat_transfer_coefficient = 10e-6
restart_source = 'weld_cp/LATEST'

# # displacements from the end of weld simulation for the newly imposed bounday conditions
# xzfix_bot_disp_x = -4.101098e-01
# xzfix_bot_disp_z = 9.673146e-02
# zfix_bot_disp_z = -2.155710e-02

# weld
total_passes = 5 #8
pass_weld_time = 120 #1200
delay_time = 0 #25 #300
total_weld_time = '${fparse pass_weld_time*total_passes + delay_time}'

# cooldown
load_release_time = 0 #360 # Release the top BCs slowly...
end_of_cooldown = 100000# 720000 # 360000 if pwht is used; 720000 if pwht is not used

dt = 100
dtmax = 5000 #3600
dtmin = 0.01 #1e-8
sync_times = '${total_weld_time} ${fparse total_weld_time+dt} ${fparse (end_of_cooldown+load_release_time)} ${fparse end_of_cooldown/2} ${end_of_cooldown}'

disp_save_in = ''
