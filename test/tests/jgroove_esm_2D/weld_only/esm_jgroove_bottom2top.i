all_blocks = 'tube head clad butter new weldpass01 weldpass02 weldpass03 weldpass04 weldpass05 weldpass06 weldpass07 weldpass08 weldpass09 weldpass10 weldpass11 weldpass12 weldpass13 weldpass14'

active_blocks = 'tube head clad butter new'

# Preheat temperature 60 F from paper
# change it to be "k"
# 20 C to k
T0 = 293.15

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

  [ext]
    type = SideSetsAroundSubdomainGenerator
    include_only_external_sides = true # not consider internal
    input = 'gmg'
    block = 'tube head clad butter'
    new_boundary = 'moving_boundary'
  []

  [fix_node]
    input = ext
    type = ExtraNodesetGenerator
    coord = '50.7971 195.483'
    use_closest_node = true
    new_boundary = 'fix_disp'
  []

  coord_type = 'RZ'

  add_subdomain_ids = '26'
  add_subdomain_names = 'new'

  add_sideset_names = 'tube_weld butter_weld'

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
    blocks_from = 'weldpass13 weldpass14 weldpass11 weldpass12 weldpass09 weldpass10 weldpass07 weldpass08 weldpass05 weldpass06 weldpass03 weldpass04 weldpass01 weldpass02'
    blocks_to = 'new new new new new new new new new new new new new new'
    execute_on = 'INITIAL TIMESTEP_BEGIN'

    block = ${all_blocks}

    # --- new for setting IC --- #

    old_subdomain_reinitialized = false
    reinitialize_subdomains = ${active_blocks}
    reinitialization_strategy = "POLYNOMIAL_NEIGHBOR"
    reinitialize_variables = "T disp_x disp_y"
    polynomial_fitters = 'extrapolation_patch_T extrapolation_patch_disp_x extrapolation_patch_disp_y'

    #
    moving_boundaries = 'moving_boundary'
    moving_boundary_subdomain_pairs = 'new weldpass02; new weldpass03; new weldpass04; new weldpass05; new weldpass06; new weldpass07; new weldpass08; new weldpass09; new weldpass10; new weldpass11; new weldpass12; new weldpass13; new weldpass14; new'
    # moving_boundary_subdomain_pairs = 'tube head;tube butter ; butter head;head clad; tube weldpass01; tube weldpass03; tube weldpass05;tube weldpass07; tube weldpass09;  tube weldpass11; tube weldpass13; butter weldpass02; butter weldpass04; butter weldpass06; butter weldpass08; butter weldpass10; butter weldpass12; butter weldpass14'
  []
[]

[UserObjects]
  [tube_weld_update]
    type = SidesetAroundSubdomainUpdater
    inner_subdomains = tube
    outer_subdomains = 'weldpass01 weldpass03 weldpass05 weldpass07 weldpass09 weldpass11 weldpass13'
    assign_outer_surface_sides = false
    update_sideset_name = tube_weld
    execute_on = 'INITIAL TIMESTEP_BEGIN TIMESTEP_END'
    execution_order_group = -1
    block = ${all_blocks}
  []
  [butter_weld_update]
    type = SidesetAroundSubdomainUpdater
    inner_subdomains = butter
    outer_subdomains = 'weldpass01 weldpass02 weldpass04 weldpass06 weldpass08 weldpass10 weldpass12 weldpass14'
    assign_outer_surface_sides = false
    update_sideset_name = butter_weld
    execute_on = 'INITIAL TIMESTEP_BEGIN TIMESTEP_END'
    execution_order_group = -1
    block = ${all_blocks}
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
        eigenstrain_names = 'thermal'
        temperature = T

        generate_output = "stress_xx stress_yy stress_zz
                           stress_xy stress_xz stress_yz
                           vonmises_stress"
      []
    []
  []
[]

[Materials]
  # begin: specific heat
  # easy tests
  # [thermal]
  #   type = ADHeatConductionMaterial
  #   thermal_conductivity = 45.0
  #   specific_heat = 0.5
  # []
  # copy from Bipul
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

  # Specific Heat (Based on Table 3 in INCONEL alloy 600)
  # Units: J/kg-K
  # Temp converted to K (C+273.15)
  # Added -1000 extrapolation point (constant from lowest table value)
  [specific_heat]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'specific_heat'
    variable = T

    # x: -1000, -150C, -100C, ... , 900C, 3000K
    x = '-1000   123.15  173.15  223.15  293.15  373.15  473.15  573.15  673.15  773.15  873.15  973.15  1073.15  1173.15  3000.0'

    # y: Constant extrapolation at ends
    y = '310.0   310.0   352.0   394.0   444.0   465.0   486.0   502.0   519.0   536.0   578.0   595.0   611.0    628.0    628.0'
  []

  # Thermal Conductivity (Based on Table 3 in INCONEL alloy 600)
  # Units: W/mm-K (Table value / 1000)
  # Temp converted to K (C+273.15)
  # Added -1000 extrapolation point (constant from lowest table value)
  [thermalconductivity]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'thermal_conductivity'
    variable = T

    # x: -1000, -150C, -100C, ... , 800C, 3000K
    x = '-1000    123.15   173.15   223.15   293.15   373.15   473.15   573.15   673.15   773.15   873.15   973.15   1073.15   3000.0'

    # y: Constant extrapolation at ends
    y = '0.0125   0.0125   0.0131   0.0136   0.0149   0.0159   0.0173   0.0190   0.0205   0.0221   0.0239   0.0257   0.0275    0.0275'
  []
  # end: specific heat

  [density]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    # from INCONEL alloy 600
    prop_values = 8.47e-6 # kg/mm^3
  []

  # Adjusted based on Table 4 (INCONEL alloy 600) AND Emc2 Paper Key Point (315C)
  [youngs_modulus_func]
    type = ADPiecewiseLinearInterpolationMaterial
    # Temperature in Kelvin (K)
    # 22C -> 295.15, 300C -> 573.15, [KEY] 315C -> 588.15, 400C -> 673.15 ...
    x = '-1000    295.15   373.15   473.15   573.15   588.15     673.15   773.15   873.15   973.15   1073.15  1173.15  1273.15  3000'

    # Young's Modulus in MPa (N/mm^2)
    # [KEY POINT] 315C -> 203165 (From Emc2 Paper)
    y = '214000.0 214000.0 210000.0 205000.0 199000.0 203165.0   193000.0 187000.0 180000.0 172000.0 164000.0 154000.0 143000.0 10000.0'

    property = youngs_modulus_prop
    variable = T
  []
  # Adjusted based on Table 4 (INCONEL alloy 600) AND Emc2 Paper Key Point (315C)
  [poissons_ratio_func]
    type = ADPiecewiseLinearInterpolationMaterial
    # Same temperature points as above to ensure consistency
    x = '-1000    295.15   373.15   473.15   573.15   588.15     673.15   773.15   873.15   973.15   1073.15  1173.15  1273.15  3000'

    # Poisson's Ratio
    # Table 4 values: 0.324 -> 0.306 (at 300C) -> 0.301 (at 400C)
    # [KEY POINT] 315C -> 0.32 (From Emc2 Paper)
    # Note: This creates a local increase (0.306 -> 0.32 -> 0.301) to match the paper exactly.
    y = '0.324    0.324    0.319    0.314    0.306    0.32       0.301    0.300    0.301    0.305    0.320    0.330    0.339    0.339'

    property = poissons_ratio_prop
    variable = T
  []
  [elasticity]
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = youngs_modulus_prop # MPa == N/mm^2
    poissons_ratio = poissons_ratio_prop
  []

  # begin: expansion
  # easy tests
  # [expansion1]
  #   type = ADComputeThermalExpansionEigenstrain
  #   temperature = T
  #   thermal_expansion_coeff = 1e-3
  #   stress_free_temperature = ${T0}
  #   eigenstrain_name = thermal_expansion
  # []
  # copy from Bipul
  [CTE]
    type = ADComputeInstantaneousThermalExpansionFunctionEigenstrain
    eigenstrain_name = thermal
    stress_free_temperature = ${T0}
    thermal_expansion_function = CTE_base
    temperature = T
    outputs = exodus
  []
  # end: expansion

  [stress]
    type = ADComputeFiniteStrainElasticStress
  []

  # begin: heat source material
  # how to set this properly??
  # [volumetric_heat] # need to be exactly this name!
  #   type = ADMovingEllipsoidalHeatSource
  #   path = 'path'
  #   power = 1000
  #   efficiency = 1
  #   scale = 1
  #   a = 6
  #   b = 2
  #   outputs = exodus
  # []
  [volumetric_heat]
    type = FunctionPathEllipsoidHeatSourceWeave
    # average values from other paper
    # unit is "mm"
    rx = 4.125
    ry = 4.125
    rz = 4.125
    power = 409.3046 # J/s # average values from other paper
    efficiency = 0.79 # average values from other paper
    function_x = "radial_centroid"
    function_y = "axis_centroid"
    function_z = "z_centroid"
    t_final = 14 # 14 weld passes
  []
  # end: heat source material

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

  # thermal exapansion begin
  # from Bipul
  # [CTE_base]
  #   type = PiecewiseLinear
  #   x = '-1000 298.15 323.15 373.15 423.15 473.15 523.15 573.15 623.15 673.15 723.15 773.15 823.15 873.15 923.15 973.15 1023.15 1523.15 1673.15 10000'
  #   y = '14.3033525e-6 14.3033525e-6 14.6621025e-6 15.3796025e-6 16.0971025e-6 16.8146025e-6 17.5321025e-6 18.2496025e-6 18.9671025e-6 19.6846025e-6 20.4021025e-6 21.1196025e-6 21.8371025e-6 22.5546025e-6 23.2721025e-6 23.9896025e-6 24.7071025e-6 31.8821025e-6 0 0'
  # []

  # Updated based on Table 3 (Image) - Coefficient of Expansion
  # Temperature converted to Kelvin (C + 273.15)
  # CTE values converted to 1/K (x 1e-6)
  # Extrapolation:
  # -1000 K: Uses value at -150 C (10.9e-6)
  # 10000 K: Uses value at 900 C (16.4e-6)
  [CTE_base]
    type = PiecewiseLinear
    x = '-1000 123.15 173.15 223.15 293.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1073.15 1173.15 10000'

    # CTE Values (1/K):
    # Based on Table 3 in  column "um/m-C"
    y = '10.9e-6 10.9e-6 11.7e-6 12.3e-6 10.4e-6 13.3e-6 13.8e-6 14.2e-6 14.5e-6 14.9e-6 15.3e-6 15.8e-6 16.1e-6 16.4e-6 16.4e-6'
  []
  # thermal exapansion end

  [isohard]
    type = PiecewiseLinear
    x = '0 0.002 0.01 10000'
    y = '235 240 480 480'
  []

  # begin: for path
  [axis_centroid] # y
    type = PiecewiseLinear
    x = '1  2  3   4   5   6   7   8   9   10  11  12  13  14'
    y = '51.260924 51.260924 57.126681 57.126681 62.990355 62.990355 68.850873 68.850873 74.706266 74.706266 80.552511 80.552511 86.379865 86.379865'
  []

  [radial_centroid] # x
    type = PiecewiseLinear
    x = '1  2  3   4   5   6   7   8   9   10  11  12  13  14'
    y = '56.808576 68.825729 56.128685 66.786055 55.449035 64.747105 54.769751 62.709253 54.091061 60.673183 53.413431 58.640294 52.737991 56.613974'
  []

  [z_centroid]
    type = ConstantFunction
    value = 0.0
  []
  # end: for path
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

  [convective_surface] # Convective Start
    type = ConvectiveFluxBC # Convective flux, e.g. q'' = h*(Tw - Tf)
    variable = T
    rate = 0.00001 # I copied it from Bipul # h = convective heat transfer coefficient (w/mm^2-K)
    initial = ${T0} # initial ambient temperature (K)
    boundary = 'tube_weld butter_weld moving_boundary' # BC applied on every interfaces
  [] # Convective End

  # [conv]
  #   type = ADConvectiveHeatFluxBC
  #   variable = T
  #   boundary = 'tube_weld butter_weld moving_boundary'
  #   T_infinity = ${T0}
  #   heat_transfer_coefficient = ${heat_transfer_coefficient}
  # []

  # DEI settings
  # we set as 60F instead
  # Nodal temperatures on the outermost vessel shell
  # nodes are held at 20°C to simulate the heat sink effect of the
  # surrounding carbon steel shell, which is not modeled
  [right]
    type = DirichletBC
    variable = T
    boundary = vessel_od
    value = ${T0}
  []

  [anchor_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'vessel_top fix_disp'
    value = 0.0
  []

  [anchor_x]
    type = DirichletBC
    variable = 'disp_x'
    boundary = fix_disp
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
  end_time = 15
  automatic_scaling = true
[]

[Outputs]
  exodus = true
  time_step_interval = 2
[]
