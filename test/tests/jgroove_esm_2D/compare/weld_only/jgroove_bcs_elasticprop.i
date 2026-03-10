[BCs]
  [anchor_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'vessel_top fix_disp'
    value = 0.0
  []

  [anchor_x]
    type = DirichletBC
    variable = disp_x
    boundary = fix_disp
    value = 0.0
  []
[]

[Materials]
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
[]
