[Problem]
  kernel_coverage_check = false
  material_coverage_check = false
  boundary_restricted_node_integrity_check = false
  material_dependency_check = false
  boundary_restricted_elem_integrity_check = false
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = ${mesh_file}
  []
  uniform_refine = 0
  add_subdomain_names = 'weld_to_base'
  add_subdomain_ids = 11
  use_displaced_mesh = false
[]
