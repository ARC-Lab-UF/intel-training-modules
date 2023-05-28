// Greg Stitt
// University of Florida
//
// saxpy_unroll.cpp
//
// This SYCL program will create a FPGA implementation of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This code extends the saxpy_single.cpp example by unrolling the loop
// within the single_task. In general, a loop within a single_task
// that does not have dependencies between iterations will be
// synthesized as a pipeline. By unrolling the loop, we are basically
// replicating that pipeline to process more inputs every cycle.
//
// Like before, we are still using the fpga_emulator selector instead
// of an actual FPGA.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>

#include <CL/sycl.hpp>
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
    cl::sycl::queue queue(sycl::ext::intel::fpga_emulator_selector_v);
    
    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	handler.single_task<class saxpy>([=]() {

	    // CHANGES FROM PREVIOUS SAXPY EXAMPLE
	    // A "pragma" is an specialized instruction given to
	    // a specific compiler to help with optimization.
	    // Here, we are telling DPC++ to unroll this loop
	    // by a factor of 4 (i.e., start 4 iterations at a time).
	    // When using other compilers that don't understand the
	    // unroll pragma, this just gets ignored.
	    //
	    // Choosing the best unroll factor usually requires
	    // knowledge of the memory bandwidth entering this
	    // pipeline. Unrolling increases bandwidth requirements,
	    // so unrolling past the point where bandwidth is
	    // exhausted will not improve performance and will
	    // only waste resources in the FPGA.
	    //
	    // It is outside the scope of this example to explain
	    // how to best determine the unroll factor. You can
	    // always do it experimentally, but even that is challenging
	    // due to FPGA compile times on the order of hours.	    
	    #pragma unroll 4
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
