T0 = 588.15
TA = 293.15

[GlobalParams]
  displacements = 'disp_x disp_y'
  block = '0'
[]

[Mesh]
  [gmg]
    type = CartesianMeshGenerator
    dim = 2
    dx = '0.5 0.5 0.5 0.5'
    dy = '0.5 0.5 0.5 0.5'
    ix = '2 2 2 2'
    iy = '2 2 2 2'
    subdomain_id = '0 0 0 0
                    0 1 1 0
                    0 0 0 0
                    0 0 0 0'
  []

  use_displaced_mesh = false
[]

[AuxVariables]
  [T_aux]
    # linear ramping up
    family = LAGRANGE
    order  = FIRST
  []
[]

[AuxKernels]
  [tempfuncaux]
    type = FunctionAux
    variable = T_aux
    function = temperature_load
  []
[]

[Functions]
  [temperature_load]
    type = PiecewiseLinear
    x = '-10 0'
    y = '${TA} ${T0}'
  []

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
        add_variables = true
        strain = SMALL
        incremental = true
        automatic_eigenstrain_names = true
        use_automatic_differentiation = true
        eigenstrain_names = 'thermal'
        temperature = T_aux

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
    temperature = T_aux
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
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  dt = 1
  start_time = -10
  end_time = 0
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
  execute_on = 'timestep_end'

  [cp]
    type = Checkpoint
    time_step_interval = 1
    num_files = 3
  []
[]
