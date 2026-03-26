[Problem]
  kernel_coverage_check = false
  material_coverage_check = false
  boundary_restricted_node_integrity_check = false
  material_dependency_check = false
  boundary_restricted_elem_integrity_check = false
  restart_file_base = ${restart_source}
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = ${restart_source}
  []
[]
