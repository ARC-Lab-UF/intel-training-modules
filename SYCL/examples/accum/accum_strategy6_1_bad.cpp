// Greg Stitt
// University of Florida
//
// accum_strategy6_1_bad.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// int accum = 0;
// for (int i=0; i < VECTOR_SIZE; i++)
//   accum += x[i];
//
// This example improves performance significantly over the previous one
// by leveraging work-groups and local memory to 1) minimize repeated accesses
// to slower global memory, and 2) minimize transfers between the host and
// device.
//
// The overall strategy is similar to before, where we index into the input
// array using a stride that increases for each iteration in order to avoid
// conflicts where work-items overwrite inputs. However, we now do this at
// a much finer granularity.
//
// Basically, we leverage this same approach, but only within work groups.
// Each group first transfers its portion of the inputs from global memory.
// Internally, each group iterates in the exact same was the previous example,
// but because we can synchronize work-items within a group, we don't have to
// leverage the host to do the synchronization. This minimizes the number
// of times the hosts has to start the kernel, and also minimizes the number
// of times the global data is copied. 
//
// For a visual explanation of this strategy, see slides sycl_accumulation.pptx.
//
// When running on the DevCloud, the execution time of this example
// for 1000000000 (1 billion) inputs was 2.4s, which was suprisingly slower than
// Strategy 4, which used the same approach without local memory. I'm not sure
// about the bottleneck here, but according to other references, this particular
// strategy tends to be fastest.
//
// IMPORTANT: Despite not producing errors for large inputs, there is actually
// a race condition in this code that we'll identify and fix in the next example.


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
    // We separate the device selection from the queue creation here
    // because we will need the device object to query information
    // about local memory.
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

    // This could potentially be optimized by moving the buffer creation
    // inside the loop and using global_inputs_remaining, which shrinks each iteration.
    // However, it seems to slow down performance, which occurs because the
    // destruction of the buffer triggers a transfer of data back to the
    // host each iteration.
    cl::sycl::buffer<int, 1> x_buf {x_h.data(), cl::sycl::range<1>(vector_size) };
    
    size_t global_inputs_remaining = vector_size;
    while(global_inputs_remaining > 1) {

      size_t num_groups = ceil(global_inputs_remaining / float(inputs_per_group));
      
      queue.submit([&](cl::sycl::handler& handler) {
	  
	  cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_write);

	  // We are using local memory, so we need an additional accessor for that memory.
	  cl::sycl::local_accessor<int, 1> x_local(cl::sycl::range<1>(work_items_per_group), handler);

	  // Unlike the previous examples, we use an nd_randge instead of range to
	  // specify work-group sizes. Also, we use an nd_item intead of an id 
	  // because the nd_item provides synchronization methods.
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
	      
	      // Wait for all work-items in the group to finish the first add.
	      // This is necessary because we need to ensure the local memory
	      // is fully loaded before doing more adds.
	      item.barrier(cl::sycl::access::fence_space::local_space);

	      // Leverage the same strategy as the previous example, just
	      // within a work-group instead of globally.
	      size_t stride = 1;
	      for (size_t local_inputs_remaining = inputs_per_group; local_inputs_remaining > 1; local_inputs_remaining = ceil(local_inputs_remaining/2.0)) {

		int base = 2*stride*local_id;
		if (2*local_id + 1 < local_inputs_remaining)
		  x_local[base] = x_local[base] + x_local[base + stride];

		stride *= 2;

		// When using work-groups, we can synchronize the execution of
		// work-items within the group, so unlike the previous
		// examples where a loop inside the kernel code would lead
		// work-items progressing through the loop at different
		// rates, we can now synchronize their execution so that
		// a new iteration does start until all local work-items
		// have finished the previous iteration.
		item.barrier(cl::sycl::access::fence_space::local_space);
	      }

	      // Write the result (x_local[0]) of the work-group to global memory
	      // for the next iteration of the outer loop. This writes the outputs
	      // sequentially (with a stride of 1), so each iteration of the
	      // outer loop is just a smaller instance of the original problem.
	      //
	      // SYNCHRONIZATION PROBLEM!!!!!!
	      //
	      // Despite not causing errors in our tests, this is incorrect code.
	      // This code is assuming that no work-group finishes before another
	      // because otherwise this line of code can overwrite the input to
	      // another work-group.
	      //
	      // For example, work-group 1 writes its outsput to x_d[1], which is
	      // part of the input for work-group 0.
	      if (local_id == 0) {
		x_d[group_id] = x_local[0];
	      }
	    });
	});
      
      queue.wait();
      global_inputs_remaining = num_groups;
    }

    // We don't have to do this here for the code to work,
    // but we want to include the output transfer times
    // in our execution time calculations. At this point,
    // x_buf hasn't been destructed yet, so we need to
    // explictly copy it before sampling the ending time.
    x_buf.get_access<cl::sycl::access::mode::read>();
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
