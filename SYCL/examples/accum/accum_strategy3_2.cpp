// Greg Stitt
// University of Florida
//
// accum_strategy3_2.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// int accum = 0;
// for (int i=0; i < VECTOR_SIZE; i++)
//   accum += x[i];
//
// In this example, we optimize the previous example by minimizing the amount
// of data that is transferred between the host and device.
//
// When running on the DevCloud, the execution time of this example
// for 1000000000 (1 billion) inputs was 13.7s.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>
#include <chrono>

#include <CL/sycl.hpp>

class accum;

void print_usage(const std::string& name) {
  std::cout << "Usage: " << name << " vector_size (must be positive)" << std::endl;      
}


int main(int argc, char* argv[]) { 

  // Check correct usage of command line.
  if (argc != 2) {
    print_usage(argv[0]);
    return 1;    
  }

  // Get vector size from command line.
  size_t vector_size;
  vector_size = atoi(argv[1]);

  if (vector_size <= 0) {
    print_usage(argv[0]);    
    return 1;    
  }

  std::chrono::time_point<std::chrono::system_clock> start_time, end_time;
  unsigned num_work_items = ceil(vector_size / 2.0);
  std::vector<int> x_h(vector_size);
  std::vector<int> y_h(vector_size);
  int correct_out = 0;

  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dist(-10, 10);

  for (size_t i=0; i < vector_size; i++) {
    x_h[i] = dist(gen);
    correct_out += x_h[i];
  }
  
  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v, [] (sycl::exception_list el) {
	for (auto ex : el) { std::rethrow_exception(ex); }
      } );

    start_time = std::chrono::system_clock::now();

    for (size_t inputs_remaining = vector_size; inputs_remaining > 1; inputs_remaining = ceil(inputs_remaining / 2.0)) {

      
      // CHANGES FROM PREVIOUS EXAMPLE
      // In the previous version of the code, we copied the entire vector
      // every iteration. However, the actual valid elements in the vector
      // are reduced by half every iteration, so that approach transferred
      // many elements that weren't needed. In this optimized approach,
      // we create the buffer with the actual amount of data that will be
      // needed. This greatly reduces communication times.
      cl::sycl::buffer<int, 1> x_buf {x_h.data(), cl::sycl::range<1>(inputs_remaining) };
      cl::sycl::buffer<int, 1> y_buf {y_h.data(), cl::sycl::range<1>(ceil(inputs_remaining/2.0)) };
      
      queue.submit([&](cl::sycl::handler& handler) {

	  cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	  cl::sycl::accessor y_d(y_buf, handler, cl::sycl::write_only);
	  
	  handler.parallel_for<class accum>(cl::sycl::range<1> { num_work_items }, [=](cl::sycl::id<1> i) {

	      if (2*i + 1 == inputs_remaining)
		y_d[i] = x_d[2*i];
	      else if (2*i + 1 < inputs_remaining)
		y_d[i] = x_d[2*i] + x_d[2*i+1];
	    });
	});
      
      queue.wait();
      y_buf.get_access<cl::sycl::access::mode::read>();
      x_h = y_h;
    }
    
    end_time = std::chrono::system_clock::now();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }

  if (correct_out != x_h[0]) {
    std::cout << "ERROR: output was " << x_h[0] << " instead of " << correct_out << std::endl;
    return 1;
  }

  std::chrono::duration<double> seconds = end_time - start_time;
  std::cout << "SUCCESS! Time: " << seconds.count() << "s" << std::endl;
  return 0;
}
