
[Postprocessors]
  [total_heat]
    type = ADElementIntegralMaterialProperty
    mat_prop = 'volumetric_heat'
  []
  # [fix_xyz_disp_x]
  #   type = PointValue
  #   variable = disp_x
  #   point = '-50.8 -3.175 101.6'
  # []
  # [fix_xyz_disp_y]
  #   type = PointValue
  #   variable = disp_y
  #   point = '-50.8 -3.175 101.6'
  # []
  # [fix_xyz_disp_z]
  #   type = PointValue
  #   variable = disp_z
  #   point = '-50.8 -3.175 101.6'
  # []
  # [fix_xy_disp_x]
  #   type = PointValue
  #   variable = disp_x
  #   point = '-50.8 -3.175 0'
  # []
  # [fix_xy_disp_y]
  #   type = PointValue
  #   variable = disp_y
  #   point = '-50.8 -3.175 0'
  # []
  # [fix_x_disp_x]
  #   type = PointValue
  #   variable = disp_x
  #   point = '-50.8 3.175 101.6'
  # []
[]

[SpatioTemporalPaths]
  [path]
    type = FunctionSpatioTemporalPath
    x = path_x
    y = path_y
    z = path_z
    update_interval = ${update_interval}
    verbose = true
    smoothing = true
    smoothing_time_window = 5 #60 #200
    smoothing_points = 20
  []
[]
#
[Functions]
  [path_x]
    type = PiecewiseLinear
    data_file = 'path_x.csv'
    format = columns
  []
  [path_y]
    type = PiecewiseLinear
    data_file = 'path_y.csv'
    format = columns
  []
  [path_z]
    type = PiecewiseLinear
    data_file = 'path_z.csv'
    format = columns
  []
[]

[Materials]
  [ellipsoidal_heat_source]
    type = ADMovingEllipsoidalHeatSource
    path = path
    power = Pfraction
    efficiency = 0.8
    scale = ${base_power}
    a = ${elip_a}
    b = ${elip_b}
    # outputs = exodus
  []
  [Pfraction]
    type = ADParsedMaterial
    property_name = 'Pfraction'
    expression = 'if(time-td<=0,0,if(time-td<=120,f1,if(time-td<=240,f2,if(time-td<=360,f3,if(time-td<=480,f4,if(time-td<=600,f5,0))))))'
    constant_names = 'td f1 f2 f3 f4 f5'
    constant_expressions = '${delay_time} 1 0.8 0.66 0.71 0.64'
    coupled_variables = 'time'
    # outputs = exodus
  []
[]

[UserObjects]
  [extrapolation_patch_T]
    type = NodalPatchRecoveryVariable
    patch_polynomial_order = SECOND
    variable = 'T'
    block = ${base_blocks}
    execute_on = 'TIMESTEP_BEGIN'
    #execute_on = 'TIMESTEP_END'
  []
  [extrapolation_patch_disp_x]
    type = NodalPatchRecoveryVariable
    patch_polynomial_order = SECOND
    variable = 'disp_x'
    block = ${base_blocks}
    execute_on = 'TIMESTEP_BEGIN'
    #execute_on = 'TIMESTEP_END'
  []
  [extrapolation_patch_disp_y]
    type = NodalPatchRecoveryVariable
    patch_polynomial_order = SECOND
    variable = 'disp_y'
    block = ${base_blocks}
    execute_on = 'TIMESTEP_BEGIN'
    #execute_on = 'TIMESTEP_END'
  []
  [extrapolation_patch_disp_z]
    type = NodalPatchRecoveryVariable
    patch_polynomial_order = SECOND
    variable = 'disp_z'
    block = ${base_blocks}
    execute_on = 'TIMESTEP_BEGIN'
    #execute_on = 'TIMESTEP_END'
  []
[]

[MeshModifiers]
  [weld]
    type = CoupledVarThresholdElementSubdomainModifier
    coupled_var = 'weld'
    criterion_type = ABOVE
    threshold = 0.999999
    subdomain_id = ${subdomain_block_id}
    #active_subdomains = ${base_blocks}
    #initialize_variables = 'disp_x disp_y disp_z T'
    #initialization_strategy = 'IC IC IC NEAREST'
    # initialization_constant = 1673
    block = ${all_blocks}
    execute_on = 'TIMESTEP_BEGIN'
    #execute_on = 'TIMESTEP_END'
    moving_boundaries = 'moving_moving'
    moving_boundary_subdomain_pairs = moving

    # --- new for setting IC --- #
    old_subdomain_reinitialized = false
    reinitialize_subdomains = ${base_blocks}

    reinitialization_strategy = "POLYNOMIAL_NEIGHBOR"
    reinitialize_variables = 'disp_x disp_y disp_z T'

    polynomial_fitters = 'extrapolation_patch_disp_x extrapolation_patch_disp_y extrapolation_patch_disp_z extrapolation_patch_T'
  []
[]

[Kernels]
  [hsource]
    type = ADMatHeatSource
    material_property = 'volumetric_heat'
    variable = T
    block = ${base_blocks}
  []
[]

# [Constraints]
#   [yequal_top_clamp]
#     type = EqualValueBoundaryConstraint
#     secondary = 'xyz_top_clamp'
#     variable = disp_y
#     penalty = 1e6
#   []
# []

[BCs]
  [xfix]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'left_fix_x right_fix_x'
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
    boundary = 'base_convNrad base_heatsink weld_convNrad' # moving
  []
  [conv]
    type = ADConvectiveHeatFluxBC
    variable = T
    boundary = 'base_convNrad base_heatsink weld_convNrad' # moving
    T_infinity = ${T0}
    heat_transfer_coefficient = ${heat_transfer_coefficient}
  []
[]

[AuxKernels]
  [phi]
    type = ParsedAux
    variable = phi
    expression = 'z/101.6'
    use_xyzt = true
    execute_on = 'INITIAL LINEAR TIMESTEP_BEGIN'
  []
  [weld1]
    type = ParsedAux
    variable = weld
    expression = "phic:=if(t<${pass_weld_time}*(n-1),0,if(t<${pass_weld_time}*n,(t-${pass_weld_time}*(n-1))/${pass_weld_time},1));
                  if(phi<=phic,1,0)"
    # expression = "phic:=if(t<${pass_weld_time}*(n-1),0,if(t<${pass_weld_time}*n,(t-${pass_weld_time}*(n-1))/${pass_weld_time},1))*2*${pi};
    #               if(phi<=phic,1,0)"
    # expression = "if(t<${delay_time}+${pass_weld_time}*(n-1),0,1)"
    constant_names = n
    constant_expressions = 1
    coupled_variables = 'phi'
    use_xyzt = true
    block = 'weldpass01'
    execute_on = 'INITIAL LINEAR TIMESTEP_BEGIN'
  []
  [weld2]
    type = ParsedAux
    variable = weld
    expression = "phic:=if(t<${pass_weld_time}*(n-1),0,if(t<${pass_weld_time}*n,(t-${pass_weld_time}*(n-1))/${pass_weld_time},1));
                  if(phi<=phic,1,0)"
    constant_names = n
    constant_expressions = 2
    coupled_variables = 'phi'
    use_xyzt = true
    block = 'weldpass02'
    execute_on = 'INITIAL LINEAR TIMESTEP_BEGIN'
  []
  [weld3]
    type = ParsedAux
    variable = weld
    expression = "phic:=if(t<${pass_weld_time}*(n-1),0,if(t<${pass_weld_time}*n,(t-${pass_weld_time}*(n-1))/${pass_weld_time},1));
                  if(phi<=phic,1,0)"
    constant_names = n
    constant_expressions = 3
    coupled_variables = 'phi'
    use_xyzt = true
    block = 'weldpass03'
    execute_on = 'INITIAL LINEAR TIMESTEP_BEGIN'
  []
  [weld4]
    type = ParsedAux
    variable = weld
    expression = "phic:=if(t<${pass_weld_time}*(n-1),0,if(t<${pass_weld_time}*n,(t-${pass_weld_time}*(n-1))/${pass_weld_time},1));
                  if(phi<=phic,1,0)"
    constant_names = n
    constant_expressions = 4
    coupled_variables = 'phi'
    use_xyzt = true
    block = 'weldpass04'
    execute_on = 'INITIAL LINEAR TIMESTEP_BEGIN'
  []
  [weld5]
    type = ParsedAux
    variable = weld
    expression = "phic:=if(t<${pass_weld_time}*(n-1),0,if(t<${pass_weld_time}*n,(t-${pass_weld_time}*(n-1))/${pass_weld_time},1));
                  if(phi<=phic,1,0)"
    constant_names = n
    constant_expressions = 5
    coupled_variables = 'phi'
    use_xyzt = true
    block = 'weldpass05'
    execute_on = 'INITIAL LINEAR TIMESTEP_BEGIN'
  []
  [tbegin]
    type = ParsedAux
    variable = tbegin
    expression = 't'
    use_xyzt = true
    block = ${weld_blocks}
    execute_on = 'INITIAL LINEAR TIMESTEP_BEGIN'
  []
[]
