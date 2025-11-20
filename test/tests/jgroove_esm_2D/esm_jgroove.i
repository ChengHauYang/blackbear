all_blocks = 'tube head clad butter new weldpass01 weldpass02 weldpass03 weldpass04 weldpass05 weldpass06 weldpass07 weldpass08 weldpass09 weldpass10 weldpass11 weldpass12 weldpass13 weldpass14'

active_blocks = 'tube head clad butter new'

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

# [MeshModifiers]
#   [esm]
#     type = SpatioTemporalPathElementSubdomainModifier
#     path = 'path'
#     radius = 0.03
#     target_subdomain = '0'
#     block = '0 1'
#     execute_on = 'TIMESTEP_BEGIN'

#     # --- new for setting IC --- #
#
# old_subdomain_reinitialized = false
# reinitialize_subdomain_ids = '1'
#     ic_strategy = "IC_POLYNOMIAL"

#     nodal_patch_recovery_uo = 'extrapolation_patch_T extrapolation_patch_disp_x extrapolation_patch_disp_y'
#   []
# []

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
        generate_output = 'vonmises_stress'
      []
    []
  []
[]

[Materials]
  [thermal]
    type = HeatConductionMaterial
    thermal_conductivity = 45.0
    specific_heat = 0.5
  []
  [density]
    type = GenericConstantMaterial
    prop_names = 'density'
    prop_values = 8000.0
  []
  [elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1e9
    poissons_ratio = 0.0
  []
  # [expansion1]
  #   type = ComputeThermalExpansionEigenstrain
  #   temperature = T
  #   thermal_expansion_coeff = 1e-7
  #   stress_free_temperature = 0
  #   eigenstrain_name = thermal_expansion
  # []
  [stress]
    type = ComputeFiniteStrainElasticStress
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
[]

[Kernels]
  [heat_conduction]
    type = HeatConduction
    variable = T
  []
  [time_derivative]
    type = HeatConductionTimeDerivative
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
    value = 0
  []

  [right]
    type = DirichletBC
    variable = T
    boundary = vessel_od
    value = 0
  []

  # [top]
  #   type = DirichletBC
  #   variable = T
  #   boundary = top
  #   value = 0
  # []

  # [bottom]
  #   type = DirichletBC
  #   variable = T
  #   boundary = bottom
  #   value = 0
  # []

  # [anchor_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   boundary = 'left right top bottom'
  #   #boundary = 'left'
  #   value = 0.0
  # []
  # [anchor_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   boundary = 'left right top bottom'
  #   #boundary =  'bottom'
  #   value = 0.0
  # []
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
