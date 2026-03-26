TA = 293.15

[GlobalParams]
  displacements = 'disp_x disp_y'
  block = '0'
  restart_file_base = preheat_cp_cp/0010
[]

[Mesh]
  [gmg]
    type = FileMeshGenerator
    file = preheat_cp_cp/0010
  []

  use_displaced_mesh = false
[]

[Variables]
  [T]
    order = FIRST
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
  # [hsource]
  #   type = ADMatHeatSource
  #   material_property = 'volumetric_heat'
  #   variable = T
  # []
[]


[Functions]
  [CTE_base]
    type = PiecewiseLinear
    x = '-1000 10000'
    y = '10.9e-6 16.4e-6'
  []

  [radial_centroid] # x
    type = PiecewiseLinear
    x = '1 10'
    y = '0.5 1.5'
  []

  [axis_centroid] # y
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



[MeshModifiers]
  [cut]
    type = SpatioTemporalPathElementSubdomainModifier
    path = 'path'
    radius = 0.15
    target_subdomain = '0'
    block = '0 1'
    execute_on = 'TIMESTEP_BEGIN'

    # --- new for setting IC --- #
    restore_overridden_dofs = true
    old_subdomain_reinitialized = false
    reinitialize_subdomains = '0'
    reinitialization_strategy = "IC"
    reinitialize_variables = "T disp_x disp_y"
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
                           max_principal_stress mid_principal_stress min_principal_stress
                           "
        material_output_order = "CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 "
      []
    []
  []
[]


[SpatioTemporalPaths]
  [path]
    type = FunctionSpatioTemporalPath
    x = radial_centroid
    y = axis_centroid

    verbose = true
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
    prop_values = ' 352.0'
  []


  [volumetric_heat]
    type = ADMovingEllipsoidalHeatSource
    path = 'path'
    power = 1
    efficiency = 1
    scale = 1
    a = 0.35
    b = 0.1
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

 [T_zero]
    type = DirichletBC
    variable = T
    boundary = 'left'
    value = ${TA}
  []

[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  dt = 1
  end_time = 10
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
  [cp]
    type = Checkpoint
    time_step_interval = 1
    num_files = 3
  []
[]
