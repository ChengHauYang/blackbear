#include "FunctionPathEllipsoidHeatSourceWeave.h"
#include "Function.h"

registerMooseObject("HeatTransferApp", FunctionPathEllipsoidHeatSourceWeave);

InputParameters
FunctionPathEllipsoidHeatSourceWeave::validParams()
{
  InputParameters params = FunctionPathEllipsoidHeatSource::validParams();
  params.set<Real>("power") = 0.0;
  params.set<Real>("rx") = 0.0;
  params.set<Real>("ry") = 0.0;
  params.set<Real>("rz") = 0.0;

  // --------- time-dependent power / efficiency ----------
  params.addParam<FunctionName>(
      "function_power", "", "Optional time-dependent heat source power P(t)");
  params.addParam<FunctionName>(
      "function_efficiency", "", "Optional time-dependent efficiency η(t)");

  // --------- time-dependent radii ----------
  params.addParam<FunctionName>(
      "heat_source_rx", "", "Optional time-dependent transverse ellipsoid radius rx(t)");
  params.addParam<FunctionName>(
      "heat_source_ry", "", "Optional time-dependent longitudinal ellipsoid radius ry(t)");
  params.addParam<FunctionName>(
      "heat_source_rz", "", "Optional time-dependent depth ellipsoid radius rz(t)");

  // --------- weave pattern ----------
  params.addParam<FunctionName>("function_weave_amp_x", "", "Weave amplitude in x-direction");
  params.addParam<FunctionName>("function_weave_amp_y", "", "Weave amplitude in y-direction");
  params.addParam<FunctionName>("function_weave_amp_z", "", "Weave amplitude in z-direction");

  params.addParam<FunctionName>(
      "function_torch_speed", "", "Torch travel speed used to compute weave frequency");

  params.addParam<Real>("wavelength", 0.0, "Wavelength of the weave pattern (0 disables weave)");

  // --------- path + normalization ----------
  params.addParam<std::string>(
      "path", "", "Name of a SpatioTemporalPath UserObject for the heat source motion.");

  params.addParam<PostprocessorName>(
      "va_postprocess", "", "Optional normalization postprocessor integral");

  params.addParam<Real>("t_final", 0.0, "After this time, volumetric heat is set to zero.");

  params.addParam<std::vector<std::vector<Real>>>(
      "no_heat_source_intervals",
      {},
      "Within the specified time intervals, no heat source is active.");

  params.addClassDescription("Generalized double ellipsoid heat source with weave, path, "
                             "variable radii, variable power and efficiency.");

  return params;
}

FunctionPathEllipsoidHeatSourceWeave::FunctionPathEllipsoidHeatSourceWeave(
    const InputParameters & parameters)
  : FunctionPathEllipsoidHeatSource(parameters),

    _function_P(isParamSetByUser("function_power") ? &getFunction("function_power") : nullptr),

    _function_efficiency(
        isParamSetByUser("function_efficiency") ? &getFunction("function_efficiency") : nullptr),

    _function_rx(isParamSetByUser("heat_source_rx") ? &getFunction("heat_source_rx") : nullptr),

    _function_ry(isParamSetByUser("heat_source_ry") ? &getFunction("heat_source_ry") : nullptr),

    _function_rz(isParamSetByUser("heat_source_rz") ? &getFunction("heat_source_rz") : nullptr),

    _function_weave_amp_x(
        isParamSetByUser("function_weave_amp_x") ? &getFunction("function_weave_amp_x") : nullptr),

    _function_weave_amp_y(
        isParamSetByUser("function_weave_amp_y") ? &getFunction("function_weave_amp_y") : nullptr),

    _function_weave_amp_z(
        isParamSetByUser("function_weave_amp_z") ? &getFunction("function_weave_amp_z") : nullptr),

    _function_torch_speed(
        isParamSetByUser("function_torch_speed") ? &getFunction("function_torch_speed") : nullptr),

    _wavelength(getParam<Real>("wavelength")),

    _path(isParamSetByUser("path") ? &getUserObjectByName<SpatioTemporalPath>("path") : nullptr),

    _va_integral(isParamSetByUser("va_postprocess") ? &getPostprocessorValue("va_postprocess")
                                                    : nullptr),

    _t_final(getParam<Real>("t_final")),
    _no_heat_source_intervals(getParam<std::vector<std::vector<Real>>>("no_heat_source_intervals"))
{
  // validation
  if (!_function_P && _P == 0.0)
    mooseError("Either function_power or power must be provided and non-zero.");

  if (!_function_rx && _rx == 0.0)
    mooseError("Either heat_source_rx or rx must be provided and non-zero.");

  if (!_function_ry && _ry == 0.0)
    mooseError("Either heat_source_ry or ry must be provided and non-zero.");

  if (!_function_rz && _rz == 0.0)
    mooseError("Either heat_source_rz or rz must be provided and non-zero.");

  for (const auto & interval : _no_heat_source_intervals)
  {
    if (interval.size() != 2)
      mooseError("Each no_heat_source_intervals entry must have exactly two values.");
    if (interval[0] >= interval[1])
      mooseError(
          "In no_heat_source_intervals, the first value must be less than the second value.");
  }
}

void
FunctionPathEllipsoidHeatSourceWeave::computeQpProperties()
{
  if (_t_final > 0.0 && _t > _t_final)
  {
    _volumetric_heat[_qp] = 0.0;
    return;
  }

  for (const auto & interval : _no_heat_source_intervals)
    if (_t > interval[0] && _t < interval[1])
    {
      _volumetric_heat[_qp] = 0.0;
      return;
    }

  const Real & x = _q_point[_qp](0);
  const Real & y = _q_point[_qp](1);
  const Real & z = _q_point[_qp](2);

  // compute center of heat source
  Real x_t, y_t, z_t;

  if (_path)
  {
    Point p = _path->position(_t);
    x_t = p(0);
    y_t = p(1);
    z_t = p(2);
  }
  else
  {
    x_t = _function_x.value(_t);
    y_t = _function_y.value(_t);
    z_t = _function_z.value(_t);
  }

  // weave frequency
  Real freq = 0.0;
  bool weave = _function_weave_amp_x || _function_weave_amp_y || _function_weave_amp_z;

  if (weave)
  {
    if (!_function_torch_speed)
      mooseError("Weave amplitude provided but function_torch_speed missing.");

    if (_wavelength == 0)
      mooseError("Weave amplitude provided but wavelength = 0.");

    freq = _function_torch_speed->value(_t) / _wavelength;
  }

  // apply weave offsets
  if (_function_weave_amp_x)
    x_t += _function_weave_amp_x->value(_t) * std::sin(2 * libMesh::pi * freq * _t);

  if (_function_weave_amp_y)
    y_t += _function_weave_amp_y->value(_t) * std::sin(2 * libMesh::pi * freq * _t);

  if (_function_weave_amp_z)
    z_t += _function_weave_amp_z->value(_t) * std::sin(2 * libMesh::pi * freq * _t);

  // time-dependent or constant values
  const Real P = _function_P ? _function_P->value(_t) : _P;
  const Real eta = _function_efficiency ? _function_efficiency->value(_t) : _eta;

  const Real rx = _function_rx ? _function_rx->value(_t) : _rx;
  const Real ry = _function_ry ? _function_ry->value(_t) : _ry;
  const Real rz = _function_rz ? _function_rz->value(_t) : _rz;

  // normalized or classical double ellipsoid field
  if (_va_integral)
  {
    _volumetric_heat[_qp] =
        P * eta * _f *
        std::exp(-((x - x_t) * (x - x_t) / (rx * rx) + (y - y_t) * (y - y_t) / (ry * ry) +
                   (z - z_t) * (z - z_t) / (rz * rz))) /
        (*_va_integral);
  }
  else
  {
    _volumetric_heat[_qp] = 6.0 * std::sqrt(3.0) * P * eta * _f /
                            (rx * ry * rz * std::pow(libMesh::pi, 1.5)) *
                            std::exp(-(3.0 * (x - x_t) * (x - x_t) / (rx * rx) +
                                       3.0 * (y - y_t) * (y - y_t) / (ry * ry) +
                                       3.0 * (z - z_t) * (z - z_t) / (rz * rz)));
  }
}
