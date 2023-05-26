// Greg Stitt
// University of Florida
//
// accum_strategy5.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// int accum = 0;
// for (int i=0; i < VECTOR_SIZE; i++)
//   accum += x[i];
//
// This example tries to improve the performance of the previous examples by
// avoiding the need for a separate output array. Instead, if we get creative
// with where we store outputs, we can guarantee that no work-item overwrites
// the inputs to another work-item, even with no execution-order guarantee.
//
// To accomplish this goal, the output of each work-item is stored at the index
// of the first input to the work-item. This works because no other work-item
// will read from that index.
//
// The side effect of this decision is that each iteration of the loop
// will have the inputs stored in different locations in the input vector.
// Basically, if the inputs are initially stored in x_h[0-7], in the second
// iteration, the inputs would be stored in x_h[0,2,4,6], and in the 3rd
// iteration, the inputs would be store in x_h[0,4], etc. Basically,
// each iteration has a "stride" that spreads out the inputs equally, but
// by an amount that increases exponentially with iterations.
//
// For a visual explanation of this indexing strategy, see slides ADDLATER.
//
// When running on the DevCloud, the execution time of this example
// for 1000000000 (1 billion) inputs was 40.37s.
//
// While this performance would suggest this approach is bad, we show in the
// next example how an extension can provide the best performance so far.

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
    // Here we track the iteration since we need that information to compute the stride.
    for (size_t inputs_remaining = vector_size, iteration = 0; inputs_remaining > 1; inputs_remaining = ceil(inputs_remaining / 2.0), iteration++) {

      // CHANGES FROM PREVIOUS EXAMPLE
      // Compute the stride.
      int stride = pow(2, iteration);

      // CHANGES FROM PREVIOUS EXAMPLE
      // IMPORTANT: One significant disdvantage of this approach is that we have
      // buffer all vector_size elements, not just inputs_remaining like we did in the previous
      // example. This is required because the inputs are now stored across the entire
      // vector, which empty indices in the middle. This approach has a massive
      // overhead because it requires the entire vector to be copied, even if there
      // are only a small number of inputs left to add.
      cl::sycl::buffer<int, 1> x_buf {x_h.data(), cl::sycl::range<1>(vector_size) };
      
      queue.submit([&](cl::sycl::handler& handler) {

	  // CHANGES FROM PREVIOUS EXAMPLE
	  // Here, we go back to using a read_write vector for inputs and outputs.
	  cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_write);

	  handler.parallel_for<class accum>(cl::sycl::range<1> { num_work_items }, [=](cl::sycl::id<1> i) {
	      
	      // CHANGES FROM PREVIOUS EXAMPLE
	      // In this example, the inputs to add are spread out by "stride"
	      // elements. We first compute the base index of the first input
	      // The second input is then located at base + stride.
	      //
	      // NOTE: We no longer need explicit code to handle odd inputs because
	      // the extra input that we previously copied will already be stored
	      // in the appropriate output index.
	      int base = 2*stride*i;
	      if (2*i + 1 < inputs_remaining)
		x_d[base] = x_d[base] + x_d[base + stride];	      
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
