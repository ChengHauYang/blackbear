#pragma once

#include "Material.h"

/**
 * A material that couples variable values and stores them into material properties.
 * This mirrors the MOOSE test object so input files can expose coupled values
 * as `<variable>_value`, `<variable>_dot`, and related properties.
 */
template <bool is_ad>
class CoupledValuesMaterialTempl : public Material
{
public:
  static InputParameters validParams();

  CoupledValuesMaterialTempl(const InputParameters & parameters);

protected:
  virtual void computeQpProperties() override;

  const GenericVariableValue<is_ad> & _value;
  const GenericVariableValue<is_ad> * _dot;
  const GenericVariableValue<is_ad> * _dot_dot;
  const VariableValue * _dot_du;
  const VariableValue * _dot_dot_du;

  const bool _output_dot;
  const bool _output_dot_dot;
  const bool _output_dot_du;
  const bool _output_dot_dot_du;

  const std::string & _var_name;
  GenericMaterialProperty<Real, is_ad> & _value_prop;
  GenericMaterialProperty<Real, is_ad> * _dot_prop;
  GenericMaterialProperty<Real, is_ad> * _dot_dot_prop;
  MaterialProperty<Real> * _dot_du_prop;
  MaterialProperty<Real> * _dot_dot_du_prop;
};

typedef CoupledValuesMaterialTempl<false> CoupledValuesMaterial;
typedef CoupledValuesMaterialTempl<true> ADCoupledValuesMaterial;
