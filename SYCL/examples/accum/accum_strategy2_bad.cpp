// Greg Stitt
// University of Florida
//
// accum_strategy2_bad.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// int accum = 0;
// for (int i=0; i < VECTOR_SIZE; i++)
//   accum += x[i];
//
// This examples fixes one bug from the previous example by synchronizing
// the start of each iteration of the for loop. However, there is another
// unaddressed synchronization problem that causes this to still fail.

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

    // CHANGES FROM PREVIOUS EXAMPLE
    // In this example, we attempt to fix the previous example by moving the for loop
    // outside of the kernel code. We then can synchronize the completion of each
    // work-item in each iteration by waiting for all of them to finish. This
    // ensures that no work-item starts a new iteration until all other work-items
    // have finished the current iteration.
    for (size_t inputs_remaining = vector_size; inputs_remaining > 1; inputs_remaining = ceil(inputs_remaining / 2.0)) {
      
      cl::sycl::buffer<int, 1> x_buf {x_h.data(), cl::sycl::range<1>(inputs_remaining) };
      
      queue.submit([&](cl::sycl::handler& handler) {
	  
	  cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_write);
	  
	  handler.parallel_for<class accum>(cl::sycl::range<1> { num_work_items }, [=](cl::sycl::id<1> i) {

	      // CHANGES FROM PREVIOUS EXAMPLE
	      // We no longer have a loop here since it was moved to the host so
	      // that we could synchronize work-items at the of each iteration.
	      //
	      // IMPORTANT: while we did successfully synchronize the start of
	      // new iterations, we have unfortunately done nothing to
	      // synchronize execution within an iteration. Consider what happens
	      // if work-item 1 executes and completes before work-item 0 starts.
	      // In this case, work-item 0's input will be overwritten before
	      // performing an add, which will corrupt the results. This occurs
	      // because execution order of work-items is not guaranteed and
	      // can happen in any order. In the next example, we look at
	      // how to solve this problem.
	      if (2*i + 1 == inputs_remaining)
		x_d[i] = x_d[2*i];
	      else if (2*i + 1 < inputs_remaining)
		x_d[i] = x_d[2*i] + x_d[2*i+1];
	    });
	});
      
      queue.wait();
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
