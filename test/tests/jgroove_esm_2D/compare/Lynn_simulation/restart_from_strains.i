
[Mesh]
  type = FileMesh
  file = simple_out.e
  coord_type = RZ
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
    mesh = 'simple_handoff_0000_mesh.xda'
    es   = 'simple_handoff_0000.xda'
    timestep = LATEST
    force_replicated_source_mesh = true
    system=nl0
    system_variables = 'disp_x disp_y'
  []
  [cooldown_soln_aux]
    type = SolutionUserObject
    mesh = 'simple_handoff_0000_mesh.xda'
    es   = 'simple_handoff_0000.xda'
    timestep = LATEST
    force_replicated_source_mesh = true
    system=aux0
    system_variables = 'th_iso_aux
      plastic_strain_xx plastic_strain_yy plastic_strain_zz plastic_strain_xy plastic_strain_xz plastic_strain_yz'
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
[]

[AuxKernels]
  [ux_read]
    type = SolutionAux
    variable = disp_aux_x
    solution = cooldown_soln
    from_variable = disp_x
    direct=true
  []
  [uy_read]
    type = SolutionAux
    variable = disp_aux_y
    solution = cooldown_soln
    from_variable = disp_y
    direct=true
  []
  #
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
[]

[Functions]
  [pl_xx_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = plastic_strain_xx
  []
  [pl_yy_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = plastic_strain_yy
  []
  [pl_zz_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = plastic_strain_zz
  []
  [pl_xy_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = plastic_strain_xy
  []
  [pl_xz_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = plastic_strain_xz
  []
  [pl_yz_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = plastic_strain_yz
  []
  [th_iso_fn]
    type = SolutionFunction
    solution = cooldown_soln_aux
    from_variable = th_iso_aux
  []
  [inE_xx_fn]
    type = ParsedFunction
    expression = plastic_strain+thermal_strain
    symbol_names = 'plastic_strain thermal_strain'
    symbol_values = 'pl_xx_fn th_iso_fn'
  []
  [inE_yy_fn]
    type = ParsedFunction
    expression = plastic_strain+thermal_strain
    symbol_names = 'plastic_strain thermal_strain'
    symbol_values = 'pl_yy_fn th_iso_fn'
  []
  [inE_zz_fn]
    type = ParsedFunction
    expression = plastic_strain+thermal_strain
    symbol_names = 'plastic_strain thermal_strain'
    symbol_values = 'pl_zz_fn th_iso_fn'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        add_variables = false
        strain = SMALL
        eigenstrain_names = 'inelastic_eigenstrain'
        generate_output = 'stress_xx stress_yy stress_zz stress_xy stress_xz stress_yz
                          strain_xx strain_yy strain_zz strain_xy strain_xz strain_yz
                            vonmises_stress max_principal_stress min_principal_stress'
      []
    []
  []
[]

[Materials]
  [inelastic_eigen]
    type = GenericFunctionRankTwoTensor
    tensor_name = inelastic_eigenstrain
    tensor_functions = 'inE_xx_fn pl_xy_fn  pl_xz_fn
                        pl_xy_fn  inE_yy_fn pl_yz_fn
                        pl_xz_fn  pl_yz_fn  inE_zz_fn'
  []
  [elastic]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 183150
    poissons_ratio = 0.3
  []
  [stress]
    type = ComputeLinearElasticStress
  []
[]

[BCs]
  [bottom_y]
    type = DirichletBC
    variable = disp_y
    boundary = bottom
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
