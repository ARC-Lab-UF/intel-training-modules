// Greg Stitt
// University of Florida
//
// saxpy_multi_device.cpp
// // This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This code uses the same 2-kernel approach as saxpy_multi_kernel.cpp.
// However, in this example, we run the two kernels on different devices,
// specifically a GPU and CPU. Note that this example is largely synthetic for
// explanation purposes.
//
// Although splitting kernels across devices can be an effective optimization,
// the expensivecommunication between devices needs to be amortized across a large
// amount of computation. In this example, each kernel performs a single add
// or multiply, which would almost always be better to "fuse" into a single
// kernel.
//
// In later examples, we benchmark the different parallelization strategies to
// determine when each strategy is most effective.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>

#include <CL/sycl.hpp>

const int VECTOR_SIZE = 1000;

const float ALLOWABLE_ERROR = 0.000001;
bool are_floats_equal(float a, float b, float abs_tol=ALLOWABLE_ERROR, float rel_tol=ALLOWABLE_ERROR) {

  float diff = fabs(a-b);
  return (diff <= abs_tol || diff <= rel_tol * fmax(fabs(a), fabs(b)));
}


class a_times_x;
class plus_y;

int main(int argc, char* argv[]) { 

  float a;
  std::vector<float> x_h(VECTOR_SIZE);
  std::vector<float> y_h(VECTOR_SIZE);
  std::vector<float> z_h(VECTOR_SIZE);
  std::vector<float> correct_out(VECTOR_SIZE);

  std::vector<float> a_times_x(VECTOR_SIZE);  
  
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_real_distribution<> dist(0, 100);
  
  a = dist(gen);
  for (size_t i=0; i < VECTOR_SIZE; i++) {
    x_h[i] = dist(gen);
    y_h[i] = dist(gen);
    z_h[i] = 0;
    correct_out[i] = a * x_h[i] + y_h[i];
  }

  try {
    // CHANGES FROM PREVIOUS EXAMPLE
    // In this example, we need two devices, so we use two selectores to
    // get access to a CPU and GPU. This will fail on a system that does not
    // have both resources. You can run it on the Intel DevCloud for demonstration.
    cl::sycl::queue queue_cpu(cl::sycl::cpu_selector_v);
    cl::sycl::queue queue_gpu(cl::sycl::gpu_selector_v);
    
    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> a_times_x_buf {a_times_x.data(), cl::sycl::range<1>(a_times_x.size()) };  
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };

    // CHANGES FROM PREVIOUS EXAMPLE
    // The kernel definition is identical to the previous example, but it is submitted
    // by the gpu queue, so it will run on the GPU.
    queue_gpu.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor a_times_x_d(a_times_x_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class a_times_x>(cl::sycl::range<1> { x_h.size() }, [=](cl::sycl::id<1> i) {
	    a_times_x_d[i] = a * x_d[i];
	  });
      });

    // CHANGES FROM PREVIOUS EXAMPLE
    // This kernel is also identical to before, but is submitted by the CPU's queue.
    // Note that again we do not need explicitly synchronization, even though the kernels
    // are being executed across multiple devices.
    queue_cpu.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor a_times_x_d(a_times_x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class plus_y>(cl::sycl::range<1> { y_h.size() }, [=](cl::sycl::id<1> i) {
	    z_d[i] = a_times_x_d[i] + y_d[i];
	  });
      });

    // We need to wait for the CPU to finish the complete SAXPY computations.
    queue_cpu.wait();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }

  for (int i=0; i < VECTOR_SIZE; i++) {    
    if (!are_floats_equal(z_h[i], correct_out[i])) {\
      std::cout << a << " * " << x_h[i] << " + " << y_h[i] << " = " << z_h[i] << "\n";      
      std::cout << std::setprecision(12)
		<< "ERROR: Execution failed. Expected output of " << correct_out[i]
		<< " instead of " << z_h[i] << std::endl;
      return 1;
    }    
  }
  
  std::cout << "SUCCESS!" << std::endl;
    
  return 0;
}
