// Greg Stitt
// University of Florida
//
// saxpy_int.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This code implements a vectorized SAXPY operation (single-precesion AX + Y).
// In this example it is implemented using integers instead of single-precision
// floats. It works for integers, but we will in the next example there are some
// dangeours practices in this code.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>

#include <CL/sycl.hpp>

const int VECTOR_SIZE = 1000;

class saxpy;

int main(int argc, char* argv[]) { 

  // Declare host variables
  float a;
  std::vector<float> x_h(VECTOR_SIZE);
  std::vector<float> y_h(VECTOR_SIZE);
  std::vector<float> z_h(VECTOR_SIZE);
  std::vector<float> correct_out(VECTOR_SIZE);

  // Use C++11 randomization for input
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dist(0, 100);

  // Randomly generate scalar value for "a".
  a = dist(gen);
  for (size_t i=0; i < VECTOR_SIZE; i++) {
    // Randomly generate input values for x and y.
    x_h[i] = dist(gen);
    y_h[i] = dist(gen);
    z_h[i] = 0;

    // Calculate correct outputs for comparison.
    correct_out[i] = a * x_h[i] + y_h[i];
  }

  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v);

    // Create the buffers for the x, y, and z vectors.
    // IMPORTANT: Notice that there is no buffer for the "a" scalar.
    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };
    
    queue.submit([&](cl::sycl::handler& handler) {

	// Accessors for the vectors.
	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	// Vectorize the SAXPY computations.
	// IMPORTANT: Notice that "a" does not use an accessor. Instead, its value is "captured" as
	// part of the lambda, which can access all variables outside its scope with the [=]
	// capture list. SYCL takes these captured variables and implicitly adds them as parameters to the
	// kernel function.
	//
	// It is not possible to capture all variable this way, otherwise we could have avoided the
	// buffer/accessor for each vector. For a complete description of rules for kernel parameter
	// passing, see 14.12.4 of the 2020 SYCL specification:
	//
	// https://registry.khronos.org/SYCL/specs/sycl-2020/html/sycl-2020.html#sec:kernel.parameter.passing
		
	handler.parallel_for<class saxpy>(cl::sycl::range<1> { x_h.size() }, [=](cl::sycl::id<1> i) {
	    z_d[i] = a * x_d[i] + y_d[i];
	  });

      });

    queue.wait();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }

  // Check for correctnesss.
  if (z_h == correct_out) {   
    std::cout << "SUCCESS!" << std::endl;
  }
  else {
    std::cout << "ERROR: Execution failed!" << std::endl;
  }
      
  return 0;
}
