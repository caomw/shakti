#include <DO/Sara/Graphics.hpp>
#include <DO/Sara/ImageIO.hpp>
#include <DO/Sara/ImageProcessing.hpp>
#include <DO/Sara/VideoIO/VideoStream.hpp>

#include <DO/Shakti/Utilities/DeviceInfo.hpp>

#include "image_processing.hpp"

namespace sara = DO::Sara;
namespace shakti = DO::Shakti;

using namespace std;
using namespace DO;
using namespace sara;


namespace {
  static Timer timer;

  void tic()
  {
    timer.restart();
  }

  void toc(const char *what)
  {
    auto time = timer.elapsedMs();
    cout << "[" << what << "] Elapsed time = " << time << " ms" << endl;
  }
}


GRAPHICS_MAIN()
{
  try
  {
    std::vector<shakti::Device> devices{ shakti::get_devices() };
    cout << devices.back() << endl;

    cout.sync_with_stdio(false);

    VideoStream video_stream{ "C:/Users/David/Desktop/Paco de Lucia & John McLaughlin - 1987-07-17 Treptower Park East-Berlin Germany 76.38 DVB-S Pro-Shot MC.mpg" };
    int video_frame_index{ 0 };
    Image<Rgb8> video_frame;
    Image<float> in_frame;
    Image<float> out_frame;

    while (video_stream.read(video_frame))
    {
      cout << "[Read frame] " << video_frame_index << "" << endl;
      if (!active_window())
        create_window(video_frame.sizes());

      tic();
      in_frame = video_frame.convert<float>();
      out_frame.resize(in_frame.sizes());
      toc("Color conversion");

      tic();
      shakti::gradient(out_frame.data(), in_frame.data(), in_frame.sizes().data());
      toc("Gradient");

      tic();
      display(out_frame);
      toc("Image display");

      ++video_frame_index;
      cout << endl;
    }

  }
  catch (std::exception& e)
  {
    cout << e.what() << endl;
  }
  return 0;
}
