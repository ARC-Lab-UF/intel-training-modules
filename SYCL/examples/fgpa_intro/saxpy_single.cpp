// Greg Stitt
// University of Florida
//
// saxpy_single.cpp
//
// This SYCL program will create a FPGA implementation of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This code implements the previous SAXPY example for an
// FPGA using a single_task (one work-item), instead of a parallel_for.
// This is a common FPGA style that allows the compiler (or high-level
// synthesis tool) to pipeline the code, as opposed to just vectorizing it.
//
// Note that other than the single_task and different selector, all other code
// is identical to the previous saxpy example, despite using an FPGA.
//
// Due to lengthy FPGA compilation times, we currently run the FPGA example
// using the fpga_emulator selector. Later examples will demonstrate how to use
// the actual FPGA.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>

#include <CL/sycl.hpp>

// To use INTEL FPGAs, we need to include this header file.
#include <sycl/ext/intel/fpga_extensions.hpp>

const int VECTOR_SIZE = 1000;

const float ALLOWABLE_ERROR = 0.000001;
bool are_floats_equal(float a, float b, float abs_tol=ALLOWABLE_ERROR, float rel_tol=ALLOWABLE_ERROR) {

  float diff = fabs(a-b);
  return (diff <= abs_tol || diff <= rel_tol * fmax(fabs(a), fabs(b)));
}


class saxpy;

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
    // FPGAs are not directly supported by SYCL, so notice that we
    // are using a different namespace (sycl::ext::intel), which
    // defines extensions from Intel.
    //
    // Also, we are not using an actual FPGA for this example. Instead,
    // we are using the fpga_emulator, which allows us to test the
    // functionality without any performance estimates.
    cl::sycl::queue queue(cl::sycl::ext::intel::fpga_emulator_selector_v);
    
    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	// CHANGES FROM PREVIOUS SAXPY EXAMPLE
	// FPGA implementations will generally use a single_task instead of a
	// parallel_for. The reason for this is that FPGA implementations
	// often exploit different types of parallelism. The parallel_for
	// creates "wide" parallelism, which FPGAs can use, but generally
	// not before trying to create "deep" parallelism in the form of
	// a pipeline. By the definition the kernel as a single work-item
	// we are allowing the compiler (high-level synthesis) to generate
	// a pipeline for the code.
	handler.single_task<class saxpy>([=]() {
	    for (size_t i=0; i < VECTOR_SIZE; i++) {
	      z_d[i] = a * x_d[i] + y_d[i];
	    }
	  });

      });

    queue.wait();
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
