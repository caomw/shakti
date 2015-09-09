// ========================================================================== //
// This file is part of DO-CV, a basic set of libraries in C++ for computer
// vision.
//
// Copyright (C) 2015 David Ok <david.ok8@gmail.com>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License v. 2.0. If a copy of the MPL was not distributed with this file,
// you can obtain one at http://mozilla.org/MPL/2.0/.
// ========================================================================== //

#ifndef DO_SHAKTI_UTILITIES_DEVICEINFO_HPP
#define DO_SHAKTI_UTILITIES_DEVICEINFO_HPP

#include <iostream>
#include <vector>
#include <utility>

#ifdef _WIN32
# include <windows.h>
#endif

#include <cuda_runtime.h>
#include <cuda_gl_interop.h>

#include <DO/Shakti/Defines.hpp>


namespace DO { namespace Shakti {

  class DO_SHAKTI_EXPORT Device
  {
  public: /* API. */
    int convert_sm_version_to_cores(int major, int minor) const;

    std::string formatted_string() const;

    std::pair<int, int> version() const;

    void make_current_device();

    void make_current_gl_device();

    void reset();

    friend std::ostream& operator<<(std::ostream& os, const Device& info);

    int warp_size() const { return properties.warpSize; }

  public: /* data members. */
    int id;
    int driver_version;
    int runtime_version;
    cudaDeviceProp properties;
  };


  int get_num_cuda_devices();

  std::vector<Device> get_devices();


} /* namespace Shakti */
} /* namespace DO */


#endif /* DO_SHAKTI_UTILITIES_DEVICEINFO_HPP */
