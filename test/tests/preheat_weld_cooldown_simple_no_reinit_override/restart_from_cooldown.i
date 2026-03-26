[Mesh]
  [gmg]
    type = FileMeshGenerator
    file = weld_cp_cp/0010
  []
  use_displaced_mesh = false
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Variables]
  [disp_x]
    family = LAGRANGE
    order = FIRST
  []
  [disp_y]
    family = LAGRANGE
    order = FIRST
  []
[]

[UserObjects]
  [cooldown_soln]
    type = SolutionUserObject
    mesh = 'cooldown_handoff_0000_mesh.xda'
    es   = 'cooldown_handoff_0000.xda'
    timestep = LATEST
    force_replicated_source_mesh = true
    system = nl0
    system_variables = 'disp_x disp_y'
  []

  [cooldown_soln_aux]
    type = SolutionUserObject
    mesh = 'cooldown_handoff_0000_mesh.xda'
    es   = 'cooldown_handoff_0000.xda'
    timestep = LATEST
    force_replicated_source_mesh = true
    system = aux0
    system_variables = 'thermal_strain_xx thermal_strain_yy thermal_strain_zz'
  []
[]

[AuxVariables]
  [disp_aux_x]
    family = LAGRANGE
    order = FIRST
  []
  [disp_aux_y]
    family = LAGRANGE
    order = FIRST
  []
  [diff_disp_x]
    family = LAGRANGE
    order = FIRST
  []
  [diff_disp_y]
    family = LAGRANGE
    order = FIRST
  []
  [diff_disp_error_x]
    family = LAGRANGE
    order = FIRST
  []
  [diff_disp_error_y]
    family = LAGRANGE
    order = FIRST
  []
[]

[AuxKernels]
  [ux_read]
    type = SolutionAux
    variable = disp_aux_x
    solution = cooldown_soln
    from_variable = disp_x
    direct = true
  []
  [uy_read]
    type = SolutionAux
    variable = disp_aux_y
    solution = cooldown_soln
    from_variable = disp_y
    direct = true
  []

  [diff_disp_x]
    type = ParsedAux
    variable = diff_disp_x
    coupled_variables = 'disp_aux_x disp_x'
    expression = 'abs(disp_aux_x - disp_x)'
  []
  [diff_disp_y]
    type = ParsedAux
    variable = diff_disp_y
    coupled_variables = 'disp_aux_y disp_y'
    expression = 'abs(disp_aux_y - disp_y)'
  []

  [diff_disp_error_x]
    type = ParsedAux
    variable = diff_disp_error_x
    coupled_variables = 'disp_aux_x disp_x'
    expression = 'abs(disp_aux_x - disp_x)/abs(disp_aux_x)'
  []

  [diff_disp_error_y]
    type = ParsedAux
    variable = diff_disp_error_y
    coupled_variables = 'disp_aux_y disp_y'
    expression = 'abs(disp_aux_y - disp_y)/abs(disp_aux_y)'
  []


[]

[Functions]
  [th_xx_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = thermal_strain_xx
  []
  [th_yy_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = thermal_strain_yy
  []
  [th_zz_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = thermal_strain_zz
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        add_variables = false
        strain = SMALL
        eigenstrain_names = 'thermal_eigenstrain'
        generate_output = 'stress_xx stress_yy stress_zz
                           stress_xy stress_xz stress_yz
                           strain_xx strain_yy strain_zz
                           strain_xy strain_xz strain_yz
                           vonmises_stress max_principal_stress min_principal_stress'
      []
    []
  []
[]

[Materials]
  [thermal_eigen]
    type = GenericFunctionRankTwoTensor
    tensor_name = thermal_eigenstrain
    tensor_functions = 'th_xx_fn 0 0
                        0 th_yy_fn 0
                        0 0 th_zz_fn'
  []

  [elastic]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1e5
    poissons_ratio = 0.3
  []

  [stress]
    type = ComputeLinearElasticStress
  []
[]

[BCs]
  [anchor_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0.0
  []
  [anchor_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom'
    value = 0.0
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
[]

[Outputs]
  exodus = true
[]
