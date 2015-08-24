#include <algorithm>

#include <DO/Shakti/Utilities.hpp>
#include <DO/Shakti/ImageProcessing.hpp>
#include <DO/Shakti/ImageProcessing/Cuda/Convolution.hpp>


namespace DO { namespace Shakti {

  void apply_row_based_convolution(
    float *out, const float *in, const float *kernel,
    int kernel_size, const int *sizes)
  {
    const dim3 block_size{ 16, 16 };
    const dim3 grid_size{
      (sizes[0] + block_size.x - 1) / block_size.x,
      (sizes[1] + block_size.y - 1) / block_size.y
    };

    tic();
    Cuda::Array<float> in_array{ in, sizes };
    MultiArray<float, 2> out_array{ sizes };
    toc("Host to device transfer");

    tic();
    CHECK_CUDA_RUNTIME_ERROR(cudaBindTextureToArray(in_float_texture, in_array));
    cudaMemcpyToSymbol(convolution_kernel, kernel, sizeof(float) * kernel_size);
    cudaMemcpyToSymbol(convolution_kernel_size, &kernel_size, sizeof(int));
    apply_row_based_convolution<<<grid_size, block_size>>>(out_array.data());
    CHECK_CUDA_RUNTIME_ERROR(cudaUnbindTexture(in_float_texture));
    toc("Row based convolution");

    tic();
    out_array.copy_to_host(out);
    toc("Device to host transfer");
  }

  void apply_column_based_convolution(
    float *out, const float *in, const float *kernel,
    int kernel_size, const int *sizes)
  {
    const dim3 block_size{ 16, 16 };
    const dim3 grid_size{
      (sizes[0] + block_size.x - 1) / block_size.x,
      (sizes[1] + block_size.y - 1) / block_size.y
    };

    tic();
    Cuda::Array<float> in_array{ in, sizes };
    MultiArray<float, 2> out_array{ sizes };
    toc("Host to device transfer");

    tic();
    CHECK_CUDA_RUNTIME_ERROR(cudaBindTextureToArray(in_float_texture, in_array));
    CHECK_CUDA_RUNTIME_ERROR(cudaMemcpyToSymbol(convolution_kernel, kernel, sizeof(float) * kernel_size));
    CHECK_CUDA_RUNTIME_ERROR(cudaMemcpyToSymbol(convolution_kernel_size, &kernel_size, sizeof(int)));
    apply_column_based_convolution<<<grid_size, block_size>>>(out_array.data());
    CHECK_CUDA_RUNTIME_ERROR(cudaUnbindTexture(in_float_texture));
    toc("Column based convolution");

    tic();
    out_array.copy_to_host(out);
    toc("Device to host transfer");
  }

} /* namespace Shakti */
} /* namespace DO */


namespace DO { namespace Shakti {

  void GaussianFilter::set_sigma(float sigma)
  {
    auto kernel_size = static_cast<int>(2.f * _truncation_factor * sigma + 1.f);
    kernel_size = std::max(3, kernel_size);
    if (kernel_size % 2 == 0)
      ++kernel_size;

    auto sum = float{ 0.f };
    _kernel.resize(kernel_size);
    for (auto i = int{ 0 }; i < kernel_size; ++i)
    {
      auto x = i - kernel_size/2;
      _kernel[i] = exp(-x*x / (2.f*sigma*sigma));
      sum += _kernel[i];
    }
    for (auto i = int{ 0 }; i < kernel_size; ++i)
      _kernel[i] /= sum;

    CHECK_CUDA_RUNTIME_ERROR(cudaMemcpyToSymbol(
      convolution_kernel, _kernel.data(), sizeof(float) * _kernel.size()));
    CHECK_CUDA_RUNTIME_ERROR(cudaMemcpyToSymbol(
      convolution_kernel_size, &kernel_size, sizeof(int)));
  }

  void GaussianFilter::operator()(float *out, const float *in, const int *sizes) const
  {
    const dim3 block_size{ 16, 16 };
    const dim3 grid_size{
      (sizes[0] + block_size.x - 1) / block_size.x,
      (sizes[1] + block_size.y - 1) / block_size.y
    };

    tic();
    Cuda::Array<float> in_array{ in, { sizes[0], sizes[1] } };
    MultiArray<float, 2> out_array{ { sizes[0], sizes[1] } };
    toc("Host to device transfer");

    tic();
    {
      CHECK_CUDA_RUNTIME_ERROR(cudaBindTextureToArray(in_float_texture, in_array));
      apply_column_based_convolution<<<grid_size, block_size>>>(out_array.data());
      in_array.copy_from(out_array.data(), out_array.sizes(), cudaMemcpyDeviceToDevice);
      apply_row_based_convolution<<<grid_size, block_size>>>(out_array.data());

      CHECK_CUDA_RUNTIME_ERROR(cudaUnbindTexture(in_float_texture));
    }
    toc("Gaussian filter");

    tic();
    out_array.copy_to_host(out);
    toc("Device to host transfer");
  }

  MultiArray<float, 2>
  GaussianFilter::operator()(Cuda::Array<float>& in) const
  {
    const auto& sizes = in.sizes();
    const dim3 block_size{ 16, 16 };
    const dim3 grid_size{
      (sizes[0] + block_size.x - 1) / block_size.x,
      (sizes[1] + block_size.y - 1) / block_size.y
    };

    MultiArray<float, 2> out{ sizes };
    CHECK_CUDA_RUNTIME_ERROR(cudaBindTextureToArray(in_float_texture, in));
    apply_column_based_convolution<<<grid_size, block_size>>>(out.data());
    in.copy_from(out.data(), out.sizes(), cudaMemcpyDeviceToDevice);
    apply_row_based_convolution<<<grid_size, block_size>>>(out.data());
    CHECK_CUDA_RUNTIME_ERROR(cudaUnbindTexture(in_float_texture));

    return out;
  }

} /* namespace Shakti */
} /* namespace DO */