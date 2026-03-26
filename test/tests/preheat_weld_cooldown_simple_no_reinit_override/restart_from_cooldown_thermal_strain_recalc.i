TA = 293.15

[Mesh]
  type = FileMesh
  file = weld_cp_cp/0010
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
    system_variables = 'disp_x disp_y T'
  []
[]

[AuxVariables]
  [disp_old_x]
    family = LAGRANGE
    order = FIRST
  []
  [disp_old_y]
    family = LAGRANGE
    order = FIRST
  []
  [T_old]
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
    variable = disp_old_x
    solution = cooldown_soln
    from_variable = disp_x
    direct = true
  []
  [uy_read]
    type = SolutionAux
    variable = disp_old_y
    solution = cooldown_soln
    from_variable = disp_y
    direct = true
  []
  [T_read]
    type = SolutionAux
    variable = T_old
    solution = cooldown_soln
    from_variable = T
    direct = true
  []

  [diff_disp_x_aux]
    type = ParsedAux
    variable = diff_disp_x
    coupled_variables = 'disp_old_x disp_x'
    expression = 'abs(disp_old_x - disp_x)'
  []
  [diff_disp_y_aux]
    type = ParsedAux
    variable = diff_disp_y
    coupled_variables = 'disp_old_y disp_y'
    expression = 'abs(disp_old_y - disp_y)'
  []
[]

[Functions]
  [CTE_base]
    type = PiecewiseLinear
    x = '-1000 10000'
    y = '10.9e-6 16.4e-6'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        add_variables = false
        strain = SMALL
        use_automatic_differentiation = true
        eigenstrain_names = 'thermal'
        generate_output = "stress_xx stress_yy stress_zz
                           stress_xy stress_xz stress_yz
                           vonmises_stress
                           strain_xx strain_yy strain_zz
                           strain_xy strain_xz strain_yz
                           max_principal_stress mid_principal_stress min_principal_stress"
        material_output_order = "CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT"
      []
    []
  []
[]

[Materials]
  [elastic_stress]
    type = ADComputeLinearElasticStress
  []
  [elasticity_tensor]
    type = ADComputeIsotropicElasticityTensor
    poissons_ratio = 0.3
    youngs_modulus = 1e5
  []

  # Reconstruct the thermal eigenstrain from the temperature field
  # saved in the previous cooldown simulation.
  [thermal_eigenstrain]
    type = ADComputeInstantaneousThermalExpansionFunctionEigenstrain
    eigenstrain_name = thermal
    stress_free_temperature = ${TA}
    thermal_expansion_function = CTE_base
    temperature = T_old
    outputs = exodus
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
  automatic_scaling = true
  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-8
  residual_and_jacobian_together = true
[]

[Outputs]
  exodus = true
[]
