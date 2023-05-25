// Greg Stitt
// University of Florida
//
// saxpy_multi_device2.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code, while parallelizing it across two devices.
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This implementation again leverages two devices, where each devices performs a
// vectorized SAXPY on half of the input vector. This style of parallelization is
// often referred to as a "scatter," which is effective, but the size of the data
// scattered to heteregenous devices often needs to be chosen carefully to ensure
// a load-balanced design. In this example, we arbitrarily chose to split the input
// in half. In general, you would benchmark each device and then choose a number of
// inputs for each device such that both devices' execution times are similar.

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


class saxpy;
class saxpy2;

int main(int argc, char* argv[]) { 

  float a;
  std::vector<float> x_h(VECTOR_SIZE);
  std::vector<float> y_h(VECTOR_SIZE);
  std::vector<float> z_h(VECTOR_SIZE);
  std::vector<float> correct_out(VECTOR_SIZE);
  
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
    cl::sycl::queue queue_gpu(cl::sycl::gpu_selector_v);
    cl::sycl::queue queue_cpu(cl::sycl::cpu_selector_v);

    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };

    // CHANGES FROM PREVIOUS EXAMPLE
    // GPU SAXPY: This code performs a normal vectorized saxpy on the GPU, but on the
    // first half of the inputs.
    queue_gpu.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class saxpy>(cl::sycl::range<1> { x_h.size() / 2 }, [=](cl::sycl::id<1> i) {
	    z_d[i] = a * x_d[i] + y_d[i];
	  });

      });

    // CHANGES FROM PREVIOUS CODE
    // CPU SAXPY: This kernel also performs a normal vectorized saxpy, but on a CPU, and
    // on the second half of the input data.
    queue_cpu.submit([&](cl::sycl::handler& handler) {

	// Note that both kernels are using the same accessors because they share the same input vectors.
	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	// A normal saxpy computation, but with adjusted indices to access the second half of the data.
	handler.parallel_for<class saxpy2>(cl::sycl::range<1> { x_h.size() / 2 }, [=](cl::sycl::id<1> i) {	    
	    int offset = i + VECTOR_SIZE / 2;
	    z_d[offset] = a * x_d[offset] + y_d[offset];
	  });

      });
    
    queue_gpu.wait();
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
