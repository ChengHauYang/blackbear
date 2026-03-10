#include "CoupledValuesMaterial.h"

registerMooseObject("BlackBearApp", CoupledValuesMaterial);
registerMooseObject("BlackBearApp", ADCoupledValuesMaterial);

template <bool is_ad>
InputParameters
CoupledValuesMaterialTempl<is_ad>::validParams()
{
  InputParameters params = Material::validParams();
  params.addRequiredCoupledVar("variable", "Coupled variable");
  params.addParam<bool>(
      "output_dot", false, "Store the coupled variable first time derivative as `<var>_dot`.");
  params.addParam<bool>("output_dot_dot",
                        false,
                        "Store the coupled variable second time derivative as `<var>_dot_dot`.");
  params.addParam<bool>(
      "output_dot_du", false, "Store the derivative of `<var>_dot` with respect to the variable.");
  params.addParam<bool>("output_dot_dot_du",
                        false,
                        "Store the derivative of `<var>_dot_dot` with respect to the variable.");
  params.addClassDescription(
      "Stores a coupled variable and its time derivatives in material properties.");
  return params;
}

template <bool is_ad>
CoupledValuesMaterialTempl<is_ad>::CoupledValuesMaterialTempl(const InputParameters & parameters)
  : Material(parameters),
    _value(coupledGenericValue<is_ad>("variable")),
    _dot(nullptr),
    _dot_dot(nullptr),
    _dot_du(nullptr),
    _dot_dot_du(nullptr),
    _output_dot(getParam<bool>("output_dot")),
    _output_dot_dot(getParam<bool>("output_dot_dot")),
    _output_dot_du(getParam<bool>("output_dot_du")),
    _output_dot_dot_du(getParam<bool>("output_dot_dot_du")),
    _var_name(getVar("variable", 0)->name()),
    _value_prop(declareGenericProperty<Real, is_ad>(_var_name + "_value")),
    _dot_prop(nullptr),
    _dot_dot_prop(nullptr),
    _dot_du_prop(nullptr),
    _dot_dot_du_prop(nullptr)
{
  if (_output_dot)
  {
    _dot = &coupledGenericDot<is_ad>("variable");
    _dot_prop = &declareGenericProperty<Real, is_ad>(_var_name + "_dot");
  }

  if (_output_dot_dot)
  {
    _dot_dot = &coupledGenericDotDot<is_ad>("variable");
    _dot_dot_prop = &declareGenericProperty<Real, is_ad>(_var_name + "_dot_dot");
  }

  if (_output_dot_du)
  {
    _dot_du = &coupledDotDu("variable");
    _dot_du_prop = &declareProperty<Real>(_var_name + "_dot_du");
  }

  if (_output_dot_dot_du)
  {
    _dot_dot_du = &coupledDotDotDu("variable");
    _dot_dot_du_prop = &declareProperty<Real>(_var_name + "_dot_dot_du");
  }
}

template <bool is_ad>
void
CoupledValuesMaterialTempl<is_ad>::computeQpProperties()
{
  _value_prop[_qp] = _value[_qp];

  if (_dot_prop)
    (*_dot_prop)[_qp] = (*_dot)[_qp];

  if (_dot_dot_prop)
    (*_dot_dot_prop)[_qp] = (*_dot_dot)[_qp];

  if (_dot_du_prop)
    (*_dot_du_prop)[_qp] = (*_dot_du)[_qp];

  if (_dot_dot_du_prop)
    (*_dot_dot_du_prop)[_qp] = (*_dot_dot_du)[_qp];
}

template class CoupledValuesMaterialTempl<false>;
template class CoupledValuesMaterialTempl<true>;
