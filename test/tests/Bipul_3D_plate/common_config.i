thickness = 'quarterinch_real_adtl_constraint' #'quarterinch_real_adtl' #'quarterinch_real' #'quarterinch_unreal'
mesh_file = 'quarterinch_real_adtl_constraint.exo' #'quarterinch_real.exo' #'quarterinch_unreal.exo'
exo_file_base = '${thickness}/out'
csv_file_base = '${thickness}/scl'
base_blocks = 'base weld_to_base'
bot_front_point = '0 -3.228 101.6'
top_front_point = '0 4.025 101.6'
bot_back_point = '0 -3.228 0'
top_back_point = '0 4.025 0'
bot_mid_point = '0 -3.228 50.8'
top_mid_point = '0 4.025 50.8'

strain = SMALL #FINITE #SMALL

T0 = 300
Tm = 1700
T_initial_condition = ${T0}
tbegin_initial_condition = 1e12
