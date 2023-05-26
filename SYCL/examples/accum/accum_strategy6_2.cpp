// Greg Stitt
// University of Florida
//
// accum_strategy6_2.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// int accum = 0;
// for (int i=0; i < VECTOR_SIZE; i++)
//   accum += x[i];
//
// This example fixes the race condition from the previous example by combining
// the strategy with Strategy 4, where we use separate input and output arrays
// on the host that get swapped (in constant time) in between iterations.
//
// When running on the DevCloud, the execution time of this example
// for 1000000000 (1 billion) inputs was 2.01s, making it nearly identical
// to accum_strategy4_1.cpp. It is surprising that the use of local memory
// does improve performance compared to Strategy4, which only used global
// memory. This is usually not the case.

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
    cl::sycl::device device;
    cl::sycl::default_selector_v(device);
    
    cl::sycl::queue queue(device, [] (sycl::exception_list el) {
	for (auto ex : el) { std::rethrow_exception(ex); }
      } );

    // We first have to decide on how many work-items there will be
    // in each group. This is often called the work-group size, but
    // I'm avoiding that name here due to many other "sizes"
    // (e.g., vectors, number of inputs, buffers, local memory, etc.).
    size_t work_items_per_group = 32;

    // Since each work-item adds two inputs, the number of inputs
    // processed by each group is the work items per group * 2.
    size_t inputs_per_group = work_items_per_group * 2;

    // Get the size of the local memory on the device.
    auto local_mem_size = device.get_info<sycl::info::device::local_mem_size>();

    // Check for errors with the local memory.
    if (local_mem_size < (work_items_per_group * sizeof(int))) {
      throw std::runtime_error("Insufficient local memory on device.");
    }
    
    start_time = std::chrono::system_clock::now();

    // CHANGES FROM PREVIOUS VERSION
    // Create the y_h output vector. This only needs one element for
    // each work-group because each work-group reduces its inputs to
    // a single sum.    
    std::vector<int> y_h(ceil(vector_size / float(inputs_per_group)));
    
    size_t global_inputs_remaining = vector_size;
    while(global_inputs_remaining > 1) {

      size_t num_groups = ceil(global_inputs_remaining / float(inputs_per_group));

      // CHANGES FROM PREVIOUS VERSION
      // Create the buffers each iteration. This is required because the vectors
      // are pointer swapped, which invalidates the old buffers.
      cl::sycl::buffer<int, 1> x_buf {x_h.data(), cl::sycl::range<1>(global_inputs_remaining) };
      cl::sycl::buffer<int, 1> y_buf {y_h.data(), cl::sycl::range<1>(num_groups) };
      
      queue.submit([&](cl::sycl::handler& handler) {
	  
	  cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
	  cl::sycl::accessor y_d(y_buf, handler, cl::sycl::write_only);

	  cl::sycl::local_accessor<int, 1> x_local(cl::sycl::range<1>(work_items_per_group), handler);

	  handler.parallel_for<class accum>(cl::sycl::nd_range<1>(num_groups * work_items_per_group, work_items_per_group), [=](cl::sycl::nd_item<1> item) {

	      // Get the global, local and group IDs from the nd_range.	      
	      size_t global_id = item.get_global_linear_id();
	      size_t local_id = item.get_local_linear_id();
	      size_t group_id = item.get_group_linear_id();

	      // Initialize the local memory for the current work-item.
	      x_local[local_id] = 0;

	      // Perform the first add from global memory, while simply
	      // copying data in the case of an odd number of inputs.
	      if (2*global_id + 1 == global_inputs_remaining) {
		x_local[local_id] = x_d[2*global_id];
	      }
	      else if (2*global_id + 1 < global_inputs_remaining) {
		x_local[local_id] = x_d[2*global_id] + x_d[2*global_id + 1];
	      }
	      
	      item.barrier(cl::sycl::access::fence_space::local_space);

	      size_t stride = 1;
	      for (size_t local_inputs_remaining = inputs_per_group; local_inputs_remaining > 1; local_inputs_remaining = ceil(local_inputs_remaining/2.0)) {

		int base = 2*stride*local_id;
		if (2*local_id + 1 < local_inputs_remaining)
		  x_local[base] = x_local[base] + x_local[base + stride];

		stride *= 2;
		item.barrier(cl::sycl::access::fence_space::local_space);
	      }

	      // CHANGES FROM PREVIOUS VERSION
	      // Here we write to y_d to avoid potentially overwriting the input
	      // to a work-group before it is read.	      
	      if (local_id == 0) {
		y_d[group_id] = x_local[0];
	      }
	    });
	});
      
      queue.wait();
      global_inputs_remaining = num_groups;

      // CHANGES FROM PREVIOUS VERSION
      // Here we make sure to swap x and y for the next iteration.
      y_buf.get_access<cl::sycl::access::mode::read>();      
      std::swap(x_h, y_h);
    }

    // CHANGES FROM PREVIOUS VERSION
    // We no longer need to manually transfer x_h here since its buffer has been destructed.
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
