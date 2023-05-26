// Greg Stitt
// University of Florida
//
// accum_strategy1_bad.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// int accum = 0;
// for (int i=0; i < VECTOR_SIZE; i++)
//   accum += x[i];
//
// This initial example shows a commonly tried strategy that appears to work
// in some cases, but has some significant bugs.
//
// See slides sycl_accumulation.pptx for a visual explanation of the strategy.
//
// A summary of the strategy is that work-item i will add 2 inputs at
// indices x[2*i] and x[2*i+1], while storing the result at x[i]. Basically,
// this strategy attempts to always store the partial sums after each iteration
// at the beginning of the vector. This strategy seems logical because then
// every iteration of the loop performs the exact same computation, just on
// a vector that is half the size of the previous iteration. This process
// repeats until there is only 1 item left in the vector.

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
  int vector_size;
  vector_size = atoi(argv[1]);

  if (vector_size <= 0) {
    print_usage(argv[0]);    
    return 1;    
  }

  std::chrono::time_point<std::chrono::system_clock> start_time, end_time;
  
  // Determine the appropriate number of work-items.
  // For even-sized vectors, each work-item adds two inputs,
  // so we need half as many work-items as elements.
  // For odd-sized vectors, we need to round up to make sure
  // we have one extra work-item. (e.g., 3 elements requires
  // 2 work-times).
  unsigned num_work_items = ceil(vector_size / 2.0);

  // Create the input/output vector.
  std::vector<int> x_h(vector_size);
  int correct_out = 0;

  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dist(-10, 10);

  for (size_t i=0; i < vector_size; i++) {
    // Use random integer between -10 and 10.
    x_h[i] = dist(gen);

    // Calculate the correct output for comparison.
    correct_out += x_h[i];
  }
  
  try {
    // Create the command queue, and use an error handler for asyncronous
    // exceptions.
    cl::sycl::queue queue(cl::sycl::default_selector_v, [] (sycl::exception_list el) {
	for (auto ex : el) { std::rethrow_exception(ex); }
      } );

    // Start timer to determine execution time.
    start_time = std::chrono::system_clock::now();
    
    cl::sycl::buffer<int, 1> x_buf {x_h.data(), cl::sycl::range<1>(vector_size) };    
    
    // Submit the accumulation kernel to the device.
    queue.submit([&](cl::sycl::handler& handler) {

	// We need the accessor to be read_write since x_d is used as input
	// and output in each iteration of the following loop.
	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_write);

	handler.parallel_for<class accum>(cl::sycl::range<1> { num_work_items }, [=](cl::sycl::id<1> i) {

	    // In every iteration, the collection of work-items will reduce
	    // an "inputs_remaining"-element array to an "inputs_remaining/2"-element array by
	    // adding all the pairs in the original array. This process
	    // continues until there is only 1 element left.
	    //
	    // IMPORTANT: This is one source of the errors in this example.
	    // If all the work-items executed perfectly in sync,
	    // this code code potentially work, but such synchronization is
	    // not guaranteed by SYCL (or most other frameworks). As a
	    // result, work-item 2 could execute multiple iterations of this
	    // loop before work-item 1 executes anything. For this
	    // strategy to work,  we need to add explicit synchronization,
	    // which we'll see in the later examples.
	    for (size_t inputs_remaining = vector_size; inputs_remaining > 1; inputs_remaining = ceil(inputs_remaining / 2.0)) {
	      
	      // If work-time i is accessing the final element of an
	      // odd-sized array, just copy that odd element.
	      if (2*i + 1 == inputs_remaining) {
		x_d[i] = x_d[2*i];
	      }
	      // If the work-item is within the range of remaining elements,
	      // add a pair of elements at 2*i and 2*i+1.
	      // It is important to check this range because every iteration,
	      // only half as many work-items will have things to add.
	      // Although we could still let the extra work-items add without
	      // affecting correctness here, we also might want to protect
	      // against a user creating more work-items that would extend
	      // past the end of the vector and illegally access other
	      // portions of device memory.
	      else if (2*i + 1 < inputs_remaining)
		x_d[i] = x_d[2*i] + x_d[2*i+1];
	    }
	  });
      });

    // Wait for the work-items to finish the accumulation.
    queue.wait();

    // Get end time to determine execution time.
    end_time = std::chrono::system_clock::now();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }

  // Verify the correct result.
  if (correct_out != x_h[0]) {
    std::cout << "ERROR: output was " << x_h[0] << " instead of " << correct_out << std::endl;
    return 1;
  }

  std::chrono::duration<double> seconds = end_time - start_time;
  std::cout << "SUCCESS! Time: " << seconds.count() << "s" << std::endl;
  return 0;
}
