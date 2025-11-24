#pragma once

#include "FunctionPathEllipsoidHeatSource.h"

class Function;

/**
 * Extended double ellipsoid heat source distribution with
 * time-dependent power, efficiency, radii, weave pattern,
 * and optional spatio-temporal path.
 */
class FunctionPathEllipsoidHeatSourceWeave : public FunctionPathEllipsoidHeatSource
{
public:
  static InputParameters validParams();

  FunctionPathEllipsoidHeatSourceWeave(const InputParameters & parameters);

protected:
  virtual void computeQpProperties() override;

  /// optional time-dependent inputs
  const Function * _function_P;
  const Function * _function_efficiency;

  const Function * _function_rx;
  const Function * _function_ry;
  const Function * _function_rz;

  const Function * _function_weave_amp_x;
  const Function * _function_weave_amp_y;
  const Function * _function_weave_amp_z;

  const Function * _function_torch_speed;

  const Real _wavelength;

  const SpatioTemporalPath * _path;

  const Real * const _va_integral;

  const Real _t_final;

  const std::vector<std::vector<Real>> _no_heat_source_intervals;
};
