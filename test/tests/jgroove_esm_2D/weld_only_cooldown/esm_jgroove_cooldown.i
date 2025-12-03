active_blocks = 'tube head clad butter new'

# Preheat temperature 60 F from paper
# change it to be "k"
# 315 C to k (grap from Table1 in Comparison of Welding Residual Stress Solutions for Control Rod Drive Mechanism Nozzles)
T0 = 588.15

# ambient temperature
TA = 293.15

[GlobalParams]
  block = ${active_blocks}
  displacements = 'disp_x disp_y'
[]

[Problem]
  kernel_coverage_check = false
  material_coverage_check = false
  restart_file_base = esm_jgroove_cp_cp/LATEST
[]

[Mesh]
  [gmg]
    type = FileMeshGenerator
    file = esm_jgroove_cp_cp/LATEST
  []

  [ext]
    type = SideSetsAroundSubdomainGenerator
    include_only_external_sides = true # not consider internal
    input = 'gmg'
    block = ${active_blocks}
    new_boundary = 'outer_boundary'
  []

  [fix_node]
    input = ext
    type = ExtraNodesetGenerator
    coord = '50.7971 195.483'
    use_closest_node = true
    new_boundary = 'fix_disp'
  []

  coord_type = 'RZ'
  rz_coord_axis = y # axial coordinate = y, radial coordinate = x

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

        # generate_output = "stress_xx stress_yy stress_zz
        #                    stress_xy stress_xz stress_yz
        #                    vonmises_stress"
        generate_output = "stress_xx stress_yy stress_zz
                           stress_xy stress_xz stress_yz
                           vonmises_stress
                           mechanical_strain_xx mechanical_strain_yy mechanical_strain_zz
                           mechanical_strain_xy mechanical_strain_xz mechanical_strain_yz
                           max_principal_stress mid_principal_stress min_principal_stress
                           plastic_strain_xx plastic_strain_yy plastic_strain_zz
                           plastic_strain_xy plastic_strain_xz plastic_strain_yz"

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

  # do not have lots of creep effects so we neglect that
  [radial_return_stress_load_alloy600]
    type = ADComputeMultipleInelasticStress
    inelastic_models = 'isoplasticity_alloy600'
    max_iterations = 1000 #default = 50
    relative_tolerance = 1e-08 #default = 1e-05
    absolute_tolerance = 1e-11 # dfault = 1e-05
    perform_finite_strain_rotations = false
    block = 'tube'
  []

  [radial_return_stress_load_sa508]
    type = ADComputeMultipleInelasticStress
    inelastic_models = 'isoplasticity_sa508'
    max_iterations = 1000 #default = 50
    relative_tolerance = 1e-08 #default = 1e-05
    absolute_tolerance = 1e-11 # dfault = 1e-05
    perform_finite_strain_rotations = false
    block = 'head'
  []

  [radial_return_stress_load_alloy182]
    type = ADComputeMultipleInelasticStress
    inelastic_models = 'isoplasticity_alloy182'
    max_iterations = 1000 #default = 50
    relative_tolerance = 1e-08 #default = 1e-05
    absolute_tolerance = 1e-11 # dfault = 1e-05
    perform_finite_strain_rotations = false
    block = 'butter new'
  []

  [radial_return_stress_load_ss309]
    type = ADComputeMultipleInelasticStress
    inelastic_models = 'isoplasticity_ss309'
    max_iterations = 1000 #default = 50
    relative_tolerance = 1e-08 #default = 1e-05
    absolute_tolerance = 1e-11 # dfault = 1e-05
    perform_finite_strain_rotations = false
    block = 'clad'
  []

  # above "radial_return_stress_load" cannot set together with this one
  # [stress]
  #   type = ADComputeFiniteStrainElasticStress
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

    x = '-1000    295.15   373.15   473.15   573.15   588.15     673.15   773.15   873.15   973.15   1073.15  1173.15  1273.15  3000'

    # Young's Modulus in MPa (N/mm^2)
    # [KEY POINT] 315C -> 203165 (From Emc2 Paper)
    y = '214000.0 214000.0 210000.0 205000.0 199000.0 203165.0 193000.0 187000.0 180000.0 172000.0 164000.0 154000.0 143000.0 10000.0'

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

  [elasticity_alloy600_alloy182]
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = youngs_modulus_prop # MPa == N/mm^2
    poissons_ratio = poissons_ratio_prop
    block = 'tube butter new'
  []

  [elasticity_sa508] # we got this at 315C
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = 183150 # MPa == N/mm^2
    poissons_ratio = 0.3
    block = 'head'
  []

  [elasticity_ss309] # we got this at 315C
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = 176290 # MPa == N/mm^2
    poissons_ratio = 0.3
    block = 'clad'
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

  # Base on paper: Comparison of Welding Residual Stress Solutions
  # for Control Rod Drive Mechanism Nozzles
  # isotropic hardening was assumed
  # but the values below are copied from Bipul
  [isoplasticity_alloy600]
    type = ADIsotropicPlasticityStressUpdate
    yield_stress = 214.2
    hardening_function = isohard_alloy600
    max_inelastic_increment = 0.0001
    relative_tolerance = 1e-08
    absolute_tolerance = 1e-11
    block = 'tube'
  []
  [isoplasticity_sa508]
    type = ADIsotropicPlasticityStressUpdate
    yield_stress = 268.9
    hardening_function = isohard_sa508
    max_inelastic_increment = 0.0001
    relative_tolerance = 1e-08
    absolute_tolerance = 1e-11
    block = 'head'
  []
  [isoplasticity_alloy182]
    type = ADIsotropicPlasticityStressUpdate
    yield_stress = 162.8
    hardening_function = isohard_alloy182
    max_inelastic_increment = 0.0001
    relative_tolerance = 1e-08
    absolute_tolerance = 1e-11
    block = 'butter new'
  []
  [isoplasticity_ss309]
    type = ADIsotropicPlasticityStressUpdate
    yield_stress = 148.8
    hardening_function = isohard_ss309
    max_inelastic_increment = 0.0001
    relative_tolerance = 1e-08
    absolute_tolerance = 1e-11
    block = 'clad'
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

  [isohard_alloy600] # find room temperature curve # different temperature data (tensor strain/ yield strain)
    type = PiecewiseLinear
    # x = '0 0.002 0.01 10000' # strain (do not have unit)
    # y = '235 240 480 480' #MPa
    x = '0 100'
    y = '214.2 215.2' # +1 suggested by Bipul
  []

  [isohard_sa508]
    type = PiecewiseLinear
    x = '0 100'
    y = '268.9 269.9'
  []

  [isohard_alloy182]
    type = PiecewiseLinear
    x = '0 100'
    y = '162.8 163.8'
  []

  [isohard_ss309]
    type = PiecewiseLinear
    x = '0 100'
    y = '148.8 149.8'
  []

  # begin: for path
  [axis_centroid] # y
    type = PiecewiseLinear
    x = '3 6 9 12 15 18 21 24 27 30 33 36 39 42'
    y = '86.379865 86.379865 80.552511 80.552511 74.706266 74.706266 68.850873 68.850873 62.990355 62.990355 57.126681 57.126681 51.260924 51.260924'
  []

  [radial_centroid] # x
    type = PiecewiseLinear
    x = '3 6 9 12 15 18 21 24 27 30 33 36 39 42'
    y = '52.737991 56.613974 53.413431 58.640294 54.091061 60.673183 54.769751 62.709253 55.449035 64.747105 56.128685 66.786055 56.808576 68.825729'
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

[BCs]

  [convective_surface] # Convective Start
    type = ADConvectiveHeatFluxBC # Convective flux, e.g. q'' = h*(Tw - Tf)
    variable = T
    boundary = 'outer_boundary' # BC applied on every interfaces
    T_infinity = ${TA} # ambient temperature (K)
    heat_transfer_coefficient = 0.00001 # I copied it from Bipul # h = convective heat transfer coefficient (w/mm^2-K)
  [] # Convective End

  # DEI settings
  # we set as 60F instead
  # Nodal temperatures on the outermost vessel shell
  # nodes are held at 20°C to simulate the heat sink effect of the
  # surrounding carbon steel shell, which is not modeled
  [right]
    type = DirichletBC
    variable = T
    boundary = vessel_od
    value = ${TA}
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
  dt = 30
  end_time = 1000000
  automatic_scaling = true
[]

[Outputs]
  exodus = true
  time_step_interval = 20
[]
