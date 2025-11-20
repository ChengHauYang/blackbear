all_blocks = 'tube head clad butter new weldpass01 weldpass02 weldpass03 weldpass04 weldpass05 weldpass06 weldpass07 weldpass08 weldpass09 weldpass10 weldpass11 weldpass12 weldpass13 weldpass14'

active_blocks = 'tube head clad butter new'

T0 = 300

[GlobalParams]
  block = ${active_blocks}
  displacements = 'disp_x disp_y'
[]

[Problem]
  kernel_coverage_check = false
  material_coverage_check = false
[]

[Mesh]
  [gmg]
    type = FileMeshGenerator
    file = "jgroove_model01.exo"
  []

  coord_type = 'RZ'

  add_subdomain_ids = '26'
  add_subdomain_names = 'new'

  rz_coord_axis = y
  use_displaced_mesh = false
[]

[Variables]
  [T]
    order = FIRST
    initial_condition = ${T0}
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
  [cut_esm]
    type = TimedSubdomainModifier
    times = '1 2 3 4 5 6 7 8 9 10 11 12 13 14'
    blocks_from = 'weldpass01 weldpass02 weldpass03 weldpass04 weldpass05 weldpass06 weldpass07 weldpass08 weldpass09 weldpass10 weldpass11 weldpass12 weldpass13 weldpass14'
    blocks_to = 'new new new new new new new new new new new new new new'
    execute_on = 'INITIAL TIMESTEP_BEGIN'

    block = ${all_blocks}

    # --- new for setting IC --- #

    old_subdomain_reinitialized = false
    reinitialize_subdomains = ${active_blocks}
    reinitialization_strategy = "POLYNOMIAL_NEIGHBOR"
    reinitialize_variables = "T disp_x disp_y"
    polynomial_fitters = 'extrapolation_patch_T extrapolation_patch_disp_x extrapolation_patch_disp_y'
  []
[]

[SpatioTemporalPaths]
  [path]
    type = CSVPiecewiseLinearSpatioTemporalPath
    file = 'weld_pass.csv'
    verbose = true
  []
[]

[Physics]

  [SolidMechanics]

    [QuasiStatic]
      [all]
        add_variables = true
        strain = FINITE
        automatic_eigenstrain_names = true
        use_automatic_differentiation = true

        generate_output = "stress_xx stress_yy stress_zz
                           stress_xy stress_xz stress_yz
                           vonmises_stress"
      []
    []
  []
[]

[Materials]
  [thermal]
    type = ADHeatConductionMaterial
    thermal_conductivity = 45.0
    specific_heat = 0.5
  []
  # [specific_heat]
  #   type = ADPiecewiseLinearInterpolationMaterial
  #   property = 'specific_heat'
  #   variable = T
  #   x = '-1000 3000'
  #   y = '550 550'
  # []
  # [thermalconductivity]
  #   type = ADPiecewiseLinearInterpolationMaterial
  #   property = 'thermal_conductivity'
  #   variable = T
  #   x = '-1000 298.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1023.15 2500 3000'
  #   y = '14.1e-3 14.1e-3 15.4e-3 16.8e-3 18.3e-3 19.7e-3 21.2e-3 22.4e-3 23.9e-3 24.6e-3 24.6e-3 24.6e-3' ##W/mm-K
  # []

  [density]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    prop_values = 8000.0
  []
  [elasticity]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 1e3
    poissons_ratio = 0.0
  []
  [expansion1]
    type = ADComputeThermalExpansionEigenstrain
    temperature = T
    thermal_expansion_coeff = 1e-3
    stress_free_temperature = ${T0}
    eigenstrain_name = thermal_expansion
  []
  [stress]
    type = ADComputeFiniteStrainElasticStress
  []
  [volumetric_heat] # need to be exactly this name!
    type = ADMovingEllipsoidalHeatSource
    path = 'path'
    power = 1000
    efficiency = 1
    scale = 1
    a = 6
    b = 2
    outputs = exodus
  []

  # Base on paper: Comparison of Welding Residual Stress Solutions
  # for Control Rod Drive Mechanism Nozzles
  # isotropic hardening was assumed
  [isoplasticity]
    type = ADIsotropicPlasticityStressUpdate
    yield_stress = 235
    hardening_function = isohard
    max_inelastic_increment = 0.0001
    relative_tolerance = 1e-08
    absolute_tolerance = 1e-11
  []
[]

[Functions]
  [isohard]
    type = PiecewiseLinear
    x = '0 0.002 0.01 10000'
    y = '235 240 480 480'
  []
[]

[Kernels]
  [heat_conduction]
    type = ADHeatConduction
    variable = T
  []
  [time_derivative]
    type = ADHeatConductionTimeDerivative
    variable = T
  []
  [hsource]
    type = ADMatHeatSource
    material_property = 'volumetric_heat'
    variable = T
  []
[]

[BCs]
  [left]
    type = DirichletBC
    variable = T
    boundary = tube_id
    value = ${T0}
  []

  [right]
    type = DirichletBC
    variable = T
    boundary = vessel_od
    value = ${T0}
  []

  [anchor_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'tube_id'
    value = 0.0
  []
  [anchor_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'tube_id'
    value = 0.0
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  nl_max_its = 100
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8
  dt = 0.1
  end_time = 20
[]

[Outputs]
  exodus = true
[]
