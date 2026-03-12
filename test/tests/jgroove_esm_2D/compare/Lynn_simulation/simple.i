
[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  [pipe]
    type = GeneratedMeshGenerator
    nx = 19
    xmin = 10
    xmax = 200
    ny = 10
    ymin=0
    ymax=100
    dim = 2
  []
  coord_type = 'RZ'
  rz_coord_axis = y
  use_displaced_mesh = false
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        add_variables = true
        strain = SMALL
        incremental = true
        eigenstrain_names = 'dummy_eigenstrain'
        use_automatic_differentiation = true
        generate_output = "stress_xx stress_yy stress_zz
                           stress_xy stress_xz stress_yz
                           vonmises_stress
                           mechanical_strain_xx mechanical_strain_yy mechanical_strain_zz
                           mechanical_strain_xy mechanical_strain_xz mechanical_strain_yz
                           max_principal_stress mid_principal_stress min_principal_stress
                           plastic_strain_xx plastic_strain_yy plastic_strain_zz
                           plastic_strain_xy plastic_strain_xz plastic_strain_yz"
        material_output_order = "CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 CONSTANT CONSTANT CONSTANT
                                 FIRST FIRST FIRST
                                 FIRST FIRST FIRST"
      []
    []
  []
[]

[Functions]
  [isohard_alloy600]
    type = PiecewiseLinear
    x = '0 100'
    y = '214.2 215.2'
  []
  [eig_function]
    type = ParsedFunction
    expression = 0.0001*(x-100)^2*t
  []
[]

[Materials]
  [radial_return_stress_load_alloy600]
    type = ADComputeMultipleInelasticStress
    inelastic_models = 'isoplasticity_alloy600'
    max_iterations = 1000 #default = 50
    relative_tolerance = 1e-08 #default = 1e-05
    absolute_tolerance = 1e-11 # dfault = 1e-05
    perform_finite_strain_rotations = false
  []
  [isoplasticity_alloy600]
    type = ADIsotropicPlasticityStressUpdate
    yield_stress = 214.2
    hardening_function = isohard_alloy600
    max_inelastic_increment = 0.0001
    relative_tolerance = 1e-08
    absolute_tolerance = 1e-11
  []
  [elastic]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 183150
    poissons_ratio = 0.3
  []
  [dummy_eigen]
    type = ADGenericFunctionRankTwoTensor
    tensor_name = dummy_eigenstrain
    tensor_functions = 'eig_function 0            0
                        0            eig_function 0
                        0            0            eig_function'
  []
[]


[AuxVariables]
  [th_iso_aux]
    family = MONOMIAL
    order = FIRST
  []
[]
[AuxKernels]
  [volumetric_dummy_eigenstrain]
    type = ADMaterialRankTwoTensorAux
    i = 0
    j = 0
    property = dummy_eigenstrain
    variable = th_iso_aux
  []
[]

[Functions]
  [inner_pressure]
    type = PiecewiseLinear
    x = '0 2 3'
    y = '0.0 800 0'
  []
  [top_shear]
    type = PiecewiseLinear
    x = '0 2 3'
    y = '0.0 200 0'
  []
[]
[BCs]
  [bottom_y]
    type = DirichletBC
    variable = disp_y
    boundary = bottom
    value = 0.0
  []
  [inside]
    type = FunctionNeumannBC
    boundary = left
    variable = disp_x
    function = inner_pressure
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  nl_rel_tol = 1e-6
  nl_abs_tol = 5e-7
  dt = 1
  end_time = 3
[]

[Outputs]
  exodus = true
  [handoff]
    type = XDA
    execute_on = 'Final'
  []
[]
