// Greg Stitt
// University of Florida
//
// saxpy_multi_kernel.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This code implements a vectorized SAXPY operation (single-precesion AX + Y) 
// across two different kernels. The first kernel handles the multiplication and
// the second kernel handles the addition. This separation of kernels is
// synthetic for explanation, but represents a common way of structuring
// code with multple functions that can be parallelized.
//
// When using multiple fine-grained kernels like in this example, it usually makes
// sense to perform "kernel fusion" and combine them into a single kernel to
// improve performance.OB

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

  // In this example, we need separate vector to buffer the intermediate
  // computation between the two kernels.
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
    cl::sycl::queue queue(cl::sycl::default_selector_v);
    
    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> a_times_x_buf {a_times_x.data(), cl::sycl::range<1>(a_times_x.size()) };  
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };

    // In the first kernel, we just do a vectorized a * x[i], and store the result into
    // the temporary buffer a_times_x.
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor a_times_x_d(a_times_x_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class a_times_x>(cl::sycl::range<1> { x_h.size() }, [=](cl::sycl::id<1> i) {
	    a_times_x_d[i] = a * x_d[i];
	  });
      });

    // In the second kernel, we do the vectorized addition of a_times_x[i] and y[i].
    // IMPORTANT: Note that there is no explicit synchronization here. Kernels are executed
    // asynchronously, so in general, the second kernel would have to wait for the first
    // kernel to finish. One advantage of SYCL is that it can automtically determine
    // dependencies when using accessors. Basically, SYCL (more specifically the compiler)
    // notices that the following kernel depends on the previous kernel (a read-after write
    // dependence), because it reads from a_times_x_d, which is written to in the previous
    // kernel. The compiler then adds in the necessary synchronization to avoid race
    // conditions. This makes the code less error prone. There are disadvantages, however,
    // which we will see in later examples on USM.
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor a_times_x_d(a_times_x_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class plus_y>(cl::sycl::range<1> { y_h.size() }, [=](cl::sycl::id<1> i) {
	    z_d[i] = a_times_x_d[i] + y_d[i];
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
