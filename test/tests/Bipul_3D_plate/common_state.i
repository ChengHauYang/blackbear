[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Variables]
  [disp_x]
    block = ${base_blocks}
  []
  [disp_y]
    block = ${base_blocks}
  []
  [disp_z]
    block = ${base_blocks}
  []
  [T]
    initial_condition = ${T_initial_condition}
    block = ${base_blocks}
  []
[]

[AuxVariables]
  [rx]
    block = ${base_blocks}
  []
  [ry]
    block = ${base_blocks}
  []
  [rz]
    block = ${base_blocks}
  []
  [time]
    order = CONSTANT
    family = MONOMIAL
  []
  [Tc]
    order = FIRST
    family = LAGRANGE
    block = ${base_blocks}
  []
  [Tk]
    order = FIRST
    family = LAGRANGE
    block = ${base_blocks}
  []
  [phi]
    order = CONSTANT
    family = MONOMIAL
  []
  [weld]
    order = CONSTANT
    family = MONOMIAL
  []
  # [a]
  #   order = CONSTANT
  #   family = MONOMIAL
  # []
  [tbegin]
    order = CONSTANT
    family = MONOMIAL
    initial_condition = ${tbegin_initial_condition}
  []
[]
