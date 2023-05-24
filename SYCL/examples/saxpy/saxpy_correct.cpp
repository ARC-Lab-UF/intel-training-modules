// Greg Stitt
// University of Florida
//
// saxpy_correct.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This code implements a vectorized SAXPY operation (single-precesion AX + Y).
// This version is "corrected" to avoid exact equality comparisons of floats.
// The outputs in the previous version were already correct within the precision limits
// of single-precision floating point.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>

#include <CL/sycl.hpp>

const int VECTOR_SIZE = 1000;

// CHANGES FROM PREVIOUS VERSION
// In the previous version of the code, the kernel code was in fact correct, but all
// error checking failed due to equality comparisons being impossible, in
// general, for floating-point variables. It is outside the scope of this example
// to explain all the causes of this problem, but the short version is that
// floating-point calculations are not associative, so performing mathematically
// equivalent operations in different orders introduces different amounts of error.
// In addition, different devices may not fully support the IEE 754 floatin-point
// standard.
//
// Here, we use a common strategy where we compare floats by seeing if they
// are "sufficiently" equal via some pre-defined absolute and relative tolerances.
//
// This allowable error was chosen arbitrarily for this example. Normally, it would
// have to be tuned specifically for the application and use case.

const float ALLOWABLE_ERROR = 0.000001;
bool are_floats_equal(float a, float b, float abs_tol=ALLOWABLE_ERROR, float rel_tol=ALLOWABLE_ERROR) {

  float diff = fabs(a-b);
  // If the difference is within the absolute tolerance, or the relative tolerance,
  // then we'll treat the floats as being "sufficiently" equal.
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
    cl::sycl::queue queue(cl::sycl::default_selector_v);
    
    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

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
  
  // CHANGES FROM PREVIOUS CODE:
  // Instead of just comparing the output vectors for equality, we iterate over them
  // and see if each pair of outputs is sufficiently equal.
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
