// Greg Stitt
// University of Florida
//
// saxpy_bad.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// This code implements a vectorized SAXPY operation (single-precesion AX + Y)
// using randomly selected real numbers between 0 and 100. The only change to the
// previous version is changing the inputs from random integers to random real
// numbers. As you will see, this change causes errors to occur, which will be
// explained in the next example.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>

#include <CL/sycl.hpp>

const int VECTOR_SIZE = 1000;

class saxpy;

int main(int argc, char* argv[]) { 

  float a;
  std::vector<float> x_h(VECTOR_SIZE);
  std::vector<float> y_h(VECTOR_SIZE);
  std::vector<float> z_h(VECTOR_SIZE);
  std::vector<float> correct_out(VECTOR_SIZE);

  std::random_device rd;
  std::mt19937 gen(rd());
  // CHANGE FROM PREVIOUS VERSION
  // In this version of the code, we randomly generate real numbers between 0 and 100
  // instead of ints.
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
  
  if (z_h == correct_out) {   
    std::cout << "SUCCESS!" << std::endl;
  }
  else {
    std::cout << "ERROR: Execution failed!" << std::endl;
  }
      
  return 0;
}
