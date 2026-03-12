# [Functions]
#   [release]
#     type = PiecewiseLinear
#     x = '${total_weld_time} ${fparse total_weld_time+load_release_time}'
#     y = '1 0'
#   []
# []

# [NodalKernels]
#   [xfix_top_clamp]
#     type = FunctionCoupledNodalForce
#     variable = disp_x
#     function = 'release'
#     coef = 1
#     v = 'rx'
#     boundary = 'xyzfix_top_clamp'
#   []
#   [yfix_top_clamp]
#     type = FunctionCoupledNodalForce
#     variable = disp_y
#     function = 'release'
#     coef = 1
#     v = 'ry'
#     boundary = 'xyzfix_top_clamp'
#   []
#   [zfix_top_clamp]
#     type = FunctionCoupledNodalForce
#     variable = disp_z
#     function = 'release'
#     coef = 1
#     v = 'rz'
#     boundary = 'xyzfix_top_clamp'
#   []
#   [xfix_bot_clamp]
#     type = FunctionCoupledNodalForce
#     variable = disp_x
#     function = 'release'
#     coef = 1
#     v = 'rx'
#     boundary = 'xzfix_bot_clamp'
#   []
#   [zfix_bot_clamp]
#     type = FunctionCoupledNodalForce
#     variable = disp_z
#     function = 'release'
#     coef = 1
#     v = 'rz'
#     boundary = 'xzfix_bot_clamp'
#   []
# []

# [BCs]
#   [xzfix_bot_disp_x]
#     type = ADDirichletBC
#     variable = disp_x
#     value = ${xzfix_bot_disp_x}
#     boundary = 'xzfix_bot'
#   []
#   [xzfix_bot_disp_z]
#     type = ADDirichletBC
#     variable = disp_z
#     value = ${xzfix_bot_disp_z}
#     boundary = 'xzfix_bot'
#   []
#   [yfix_bot]
#     type = ADDirichletBC
#     variable = disp_y
#     value = 0
#     boundary = 'yfix_bot'
#   []
#   [zfix_bot_disp_z]
#     type = ADDirichletBC
#     variable = disp_z
#     value = ${zfix_bot_disp_z}
#     boundary = 'zfix_bot'
#   []
#   [rad]
#     type = ADMatNeumannBC
#     variable = T
#     value = -1
#     boundary_material = rad
#     boundary = 'od_base id_base'
#   []
#   [conv]
#     type = ADConvectiveHeatFluxBC
#     variable = T
#     boundary = 'od_base id_base'
#     T_infinity = ${T0}
#     heat_transfer_coefficient = ${heat_transfer_coefficient}
#   []
# []

[BCs]
  [xfix]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'fix_xyz fix_xz fix_x'
  []
  [yfix]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'fix_xyz'
  []
  [zfix]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'fix_xyz fix_xz'
  []
  [rad]
    type = ADMatNeumannBC
    variable = T
    value = -1
    boundary_material = rad
    boundary = 'base_convNrad base_heatsink weld_convNrad' # moving'
  []
  [conv]
    type = ADConvectiveHeatFluxBC
    variable = T
    boundary = 'base_convNrad base_heatsink weld_convNrad' # moving'
    T_infinity = ${T0}
    heat_transfer_coefficient = ${heat_transfer_coefficient}
  []
[]
