[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = out/cooldown.e
  []
  coord_type = 'RZ'
[]

[AuxVariables]
  [T]
    initial_condition = 293.15
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        add_variables = true
        strain = SMALL
        incremental = false
        eigenstrain_names = 'reconst_eigenstrain'
        use_automatic_differentiation = true
        generate_output = "stress_xx stress_yy stress_zz stress_xy stress_xz stress_yz
                           min_principal_stress max_principal_stress vonmises_stress"
      []
    []
  []
[]

[Constraints]
  [x1]
    type = EqualValueBoundaryConstraint
    variable = disp_x # x-component corresponds to r-direction in r–z axisymmetry
    secondary = 'vessel_od' # boundary
    penalty = 1e6
  []
[]

[BCs]
  [anchor_y]
    type = DirichletBC
    variable = disp_y # y-component corresponds to z-direction in r–z axisymmetry
    boundary = 'fix_disp'
    value = 0.0
  []
[]

[UserObjects]
  [sol]
    type = SolutionUserObject
    mesh = out/cooldown.e
    timestep = 'LATEST'
  []
[]

[Functions]
  [reconst_eigenstrain_xx]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_00'
  []
  [reconst_eigenstrain_xy]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_01'
  []
  [reconst_eigenstrain_xz]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_02'
  []
  [reconst_eigenstrain_yx]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_10'
  []
  [reconst_eigenstrain_yy]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_11'
  []
  [reconst_eigenstrain_yz]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_12'
  []
  [reconst_eigenstrain_zx]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_20'
  []
  [reconst_eigenstrain_zy]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_21'
  []
  [reconst_eigenstrain_zz]
    type = SolutionFunction
    solution = 'sol'
    from_variable = 'reconst_eigenstrain_22'
  []
[]

[Materials]
  [reconst_eigenstrain]
    type = ADGenericFunctionRankTwoTensor
    tensor_name = 'reconst_eigenstrain'
    tensor_functions = 'reconst_eigenstrain_xx reconst_eigenstrain_yx reconst_eigenstrain_yz reconst_eigenstrain_xy reconst_eigenstrain_yy reconst_eigenstrain_zy reconst_eigenstrain_xz reconst_eigenstrain_yz reconst_eigenstrain_zz'
    outputs = 'exodus'
  []
  [density]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    prop_values = 8.47e-6 # kg/mm^3
  []
  [youngs_modulus_func]
    type = ADPiecewiseLinearInterpolationMaterial

    x = '-1000    295.15   373.15   473.15   573.15   588.15     673.15   773.15   873.15   973.15   1073.15  1173.15  1273.15  3000'
    y = '214000.0 214000.0 210000.0 205000.0 199000.0 203165.0 193000.0 187000.0 180000.0 172000.0 164000.0 154000.0 143000.0 10000.0'

    property = youngs_modulus_prop
    variable = T
  []
  [poissons_ratio_func]
    type = ADPiecewiseLinearInterpolationMaterial

    x = '-1000    295.15   373.15   473.15   573.15   588.15     673.15   773.15   873.15   973.15   1073.15  1173.15  1273.15  3000'
    y = '0.324    0.324    0.319    0.314    0.306    0.32       0.301    0.300    0.301    0.305    0.320    0.330    0.339    0.339'

    property = poissons_ratio_prop
    variable = T
  []
  [elasticity_alloy600_alloy182]
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = youngs_modulus_prop # MPa == N/mm^2
    poissons_ratio = poissons_ratio_prop
    block = 'tube butter weld'
  []
  [elasticity_sa508]
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = 183150 # MPa == N/mm^2
    poissons_ratio = 0.3
    block = 'head'
  []
  [elasticity_ss309]
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = 176290 # MPa == N/mm^2
    poissons_ratio = 0.3
    block = 'clad'
  []
  [stress]
    type = ADComputeLinearElasticStress
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-08
  num_steps = 1
[]

[Outputs]
  exodus = true
[]
