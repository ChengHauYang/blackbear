TA = 293.15

[GlobalParams]
  displacements = 'disp_x disp_y'
  restart_file_base = weld_cp_cp/0010
[]

[Mesh]
  [gmg]
    type = FileMeshGenerator
    file = weld_cp_cp/0010
  []
  use_displaced_mesh = false
[]

[Variables]
  [T]
    order = FIRST
  []
[]

[AuxVariables]
  [thermal_strain_xx]
    family = MONOMIAL
    order = CONSTANT
  []
  [thermal_strain_yy]
    family = MONOMIAL
    order = CONSTANT
  []
  [thermal_strain_zz]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Kernels]
  [heat_conduction]
    type = ADHeatConduction
    thermal_conductivity = thermal_conductivity
    variable = T
  []
  [time_derivative]
    type = ADHeatConductionTimeDerivative
    density_name = density
    specific_heat = specific_heat
    variable = T
  []
[]

[Functions]
  [CTE_base]
    type = PiecewiseLinear
    x = '-1000 10000'
    y = '10.9e-6 16.4e-6'
  []

  [radial_centroid]
    type = PiecewiseLinear
    x = '1 10'
    y = '0.5 1.5'
  []

  [axis_centroid]
    type = ConstantFunction
    value = 0.75
  []

  [z_centroid]
    type = ConstantFunction
    value = 0.0
  []
[]

[UserObjects]
  [extrapolation_patch_T]
    type = NodalPatchRecoveryVariable
    patch_polynomial_order = FIRST
    variable = 'T'
    execute_on = 'TIMESTEP_BEGIN'
  []
  [extrapolation_patch_disp_x]
    type = NodalPatchRecoveryVariable
    patch_polynomial_order = FIRST
    variable = 'disp_x'
    execute_on = 'TIMESTEP_BEGIN'
  []
  [extrapolation_patch_disp_y]
    type = NodalPatchRecoveryVariable
    patch_polynomial_order = FIRST
    variable = 'disp_y'
    execute_on = 'TIMESTEP_BEGIN'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        add_variables = true
        strain = SMALL
        incremental = true
        automatic_eigenstrain_names = true
        use_automatic_differentiation = true
        eigenstrain_names = 'thermal'
        temperature = T

        generate_output = "stress_xx stress_yy stress_zz
                           stress_xy stress_xz stress_yz
                           vonmises_stress
                           mechanical_strain_xx mechanical_strain_yy mechanical_strain_zz
                           mechanical_strain_xy mechanical_strain_xz mechanical_strain_yz
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

  [CTE]
    type = ADComputeInstantaneousThermalExpansionFunctionEigenstrain
    eigenstrain_name = thermal
    stress_free_temperature = ${TA}
    thermal_expansion_function = CTE_base
    temperature = T
    outputs = exodus
  []

  [thermalconductivity]
    type = ADGenericConstantMaterial
    prop_names = 'thermal_conductivity'
    prop_values = '0.0173'
  []
  [density]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    prop_values = 8.47e-6
  []
  [specific_heat]
    type = ADGenericConstantMaterial
    prop_names = 'specific_heat'
    prop_values = '352.0'
  []
[]

[AuxKernels]
  [th_xx]
    type = ADMaterialRankTwoTensorAux
    property = thermal
    variable = thermal_strain_xx
    i = 0
    j = 0
  []
  [th_yy]
    type = ADMaterialRankTwoTensorAux
    property = thermal
    variable = thermal_strain_yy
    i = 1
    j = 1
  []
  [th_zz]
    type = ADMaterialRankTwoTensorAux
    property = thermal
    variable = thermal_strain_zz
    i = 2
    j = 2
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

  [T_zero]
    type = DirichletBC
    variable = T
    boundary = 'left'
    value = ${TA}
  []

  [convective_surface]
    type = ADConvectiveHeatFluxBC
    variable = T
    boundary = 'right top bottom'
    T_infinity = ${TA}
    heat_transfer_coefficient = 0.00001
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  dt = 100
  end_time = 5000
  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-8
  residual_and_jacobian_together = true
[]

[Postprocessors]
  [time]
    type = TimePostprocessor
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Outputs]
  exodus = true
  [handoff]
    type = XDA
    execute_on = 'FINAL'
    file_base = 'cooldown_handoff'
  []
[]
