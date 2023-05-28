// Greg Stitt
// University of Florida
//
// usm_vs_buffers1.cpp
//
// This example uses a kernel that simply copies an input vector to and
// output vector using different communication methods.
//
// The example is intended to compare buffers/accessors with Unified Shared Memory (USM).
// USM has three different allocation modes: device, host, and shared.
// Device allocation allocates memory on the device that is only accessible from the device
// and requires explicit transfers to/from the host.
// Shared allocation enables allocation to migrate between the host and device, with all
// transfers being implict.
// Host allocation uses host memory with implicit transfers.
//
// When running on the DevCloud with 1B inputs, these were the execution times.
//
// Buffers: 2.8734s
// USM malloc_shared: 0.798599s
// USM malloc_host: 0.80254s
// USM malloc_device: 2.64276s
//
// For 1000 inputs, the execution times were:
//
// Buffers: 0.0686288s
// USM malloc_shared: 9.0011e-05s
// USM malloc_host: 5.3256e-05s
// USM malloc_device: 0.000389817s
//
// Similar trends are seen for different input sizes.
//
// In general, buffers/accessors have the most overhead for these experiments.
// Explicit transfers with USM device allocation are slower than both implicit approaches.
// It is not clear why the implicit USM transfers are so much faster, but I suspect the
// compiler is overlapping the transfers with computation. I would expect these results to
// change significantly with different compilers and/or devices, so it would be a good idea
// to repeat this analysis for your targeted environment.
//
// One consequence of using the implicit transfers if that you really don't know
// when data is or will be transfered. It might vary from different compilers and
// devices. You can use explicit transfers to avoid this, but considering the
// improved performance, it would be best to profile your target environment first.
//
// TODO: Figure out why shared and host times swap when you change their order in the code.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <chrono>

#include <CL/sycl.hpp>

class copy_buffer;
class copy_usm_implicit;
class copy_usm_explicit;

void print_usage(const std::string& name) {
  std::cout << "Usage: " << name << " vector_size (must be positive)" << std::endl;      
}


// Copy function for buffers/accessors.

void copy_buffer(cl::sycl::queue &queue, const std::vector<int> &x_h, std::vector<int> &y_h) {

  if (x_h.size() != y_h.size()) {
    throw std::runtime_error("Vectors have different sizes");
  }
  
  cl::sycl::buffer<int, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
  cl::sycl::buffer<int, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };

  queue.submit([&](cl::sycl::handler& handler) {

      cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);
      cl::sycl::accessor y_d(y_buf, handler, cl::sycl::write_only);

      handler.parallel_for<class copy_buffer>(cl::sycl::range<1> { x_h.size() }, [=](cl::sycl::id<1> i) {

	  y_d[i] = x_d[i];
	});
    });

  queue.wait_and_throw();  
}


// Copy function for USM allocation methods with implicit transfers.

void copy_usm_implicit(cl::sycl::queue &queue, const int *x_d, int *y_d, size_t vector_size) {

  queue.submit([&](cl::sycl::handler& handler) {

      handler.parallel_for<class copy_usm_implicit>(cl::sycl::range<1> { vector_size }, [=](cl::sycl::id<1> i) {

	  y_d[i] = x_d[i];
	});
    });

  queue.wait_and_throw();  
}


// Copy function for USM device allocation with explicit transfers.

void copy_usm_explicit(cl::sycl::queue &queue, const std::vector<int> &x_h, std::vector<int> &y_h) {

  if (x_h.size() != y_h.size()) {
    throw std::runtime_error("Vectors have different sizes");
  }

  // Allocate memory on the device.
  int *x_d = cl::sycl::malloc_device<int>(x_h.size(), queue);
  int *y_d = cl::sycl::malloc_device<int>(y_h.size(), queue);

  // Explicitly transfer inputs to device.
  queue.memcpy(x_d, x_h.data(), sizeof(int) * x_h.size());
  
  queue.submit([&](cl::sycl::handler& handler) {

      handler.parallel_for<class copy_usm_explicit>(cl::sycl::range<1> { x_h.size() }, [=](cl::sycl::id<1> i) {

	  y_d[i] = x_d[i];
	});
    });

  // Explicitly copy the output back to the host.  
  queue.memcpy(y_h.data(), y_d, sizeof(int) * y_h.size());
  queue.wait_and_throw();

  // Free the device memory.
  cl::sycl::free(x_d, queue);
  cl::sycl::free(y_d, queue);
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
  std::vector<int> y_h(vector_size); 

  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dist(-10, 10);

  for (size_t i=0; i < vector_size; i++) {
    x_h[i] = dist(gen);
    y_h[i] = 0;
  }
  
  try {

    cl::sycl::device device;
    cl::sycl::default_selector_v(device);
        
    cl::sycl::queue queue(cl::sycl::default_selector_v, [] (sycl::exception_list el) {
	for (auto ex : el) { std::rethrow_exception(ex); }
      } );

    ////////////////////////////////////////////////////////////////////////////
    // BEGIN TEST BUFFER/ACCESSOR METHOD
    
    start_time = std::chrono::system_clock::now();
    copy_buffer(queue, x_h, y_h);

    // We normally would exclude this comparison from execution time, but
    // we include it to be more fair to the implicit USM methods.
    if (x_h != y_h) {
      std::cout << "ERROR: buffer execution failed." << std::endl;
      return 1;
    }
    end_time = std::chrono::system_clock::now();
    std::chrono::duration<double> buffer_time = end_time - start_time;

    // END TEST BUFFER/ACCESSOR METHOD
    ////////////////////////////////////////////////////////////////////////////

    
    ////////////////////////////////////////////////////////////////////////////
    // BEGIN TEST USM IMPLICIT TRANSFERS USING MALLOC_SHARED   
       
    // Create memory for USM shared allocation, where memory is accesible on host
    // and device, and transfers are implicit. We exclude this from the
    // execution time because host memory must be allocated for all approaches.
    // However, it might be worth investigating how much slower malloc_shared
    // is compared to traditional C++ allocation.
    int *x_usm_shared = cl::sycl::malloc_shared<int>(vector_size, queue);
    int *y_usm_shared = cl::sycl::malloc_shared<int>(vector_size, queue);
    memset(y_usm_shared, 0, sizeof(int) * vector_size);
    
    start_time = std::chrono::system_clock::now();

    // We include initialization of the x_usm_shared array in the execution time
    // because this can potentially trigger transfers to the device.
    for (size_t i=0; i < vector_size; i++)
      x_usm_shared[i] = x_h[i];      
    
    copy_usm_implicit(queue, x_usm_shared, y_usm_shared, vector_size);

    // We have to include this comparison in the execution time because it
    // can trigger reads from the device back to the host.
    if (memcmp(x_usm_shared, y_usm_shared, sizeof(int) * vector_size)) {
      std::cout << "ERROR: USM malloc_shared execution failed." << std::endl;
      return 1;
    }
    end_time = std::chrono::system_clock::now();    
    std::chrono::duration<double> shared_time = end_time - start_time;
    cl::sycl::free(x_usm_shared, queue);
    cl::sycl::free(y_usm_shared, queue);

    // END TEST USM IMPLICIT TRANSFERS USING MALLOC_SHARED   
    ////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////////
    // BEGIN TEST USM IMPLICIT TRANSFERS USING MALLOC_HOST
    //
    // This is identical to the malloc_shared test, but uses malloc_host instead.
    
    int *x_usm_host = cl::sycl::malloc_host<int>(vector_size, queue);
    int *y_usm_host = cl::sycl::malloc_host<int>(vector_size, queue);
    memset(y_usm_host, 0, sizeof(int) * vector_size);
    
    start_time = std::chrono::system_clock::now();
    for (size_t i=0; i < vector_size; i++)
      x_usm_host[i] = x_h[i];      
    
    copy_usm_implicit(queue, x_usm_host, y_usm_host, vector_size);
    if (memcmp(x_usm_host, y_usm_host, sizeof(int) * vector_size)) {
      std::cout << "ERROR: USM malloc_host execution failed." << std::endl;
      return 1;
    }       
    end_time = std::chrono::system_clock::now();
    std::chrono::duration<double> host_time = end_time - start_time;
    cl::sycl::free(x_usm_host, queue);
    cl::sycl::free(y_usm_host, queue);

    // END TEST USM IMPLICIT TRANSFERS USING MALLOC_HOST  
    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////
    // BEGIN TEST USM EXPLICIT TRANSFERS USING MALLOC_DEVICE

    // Reset the y_h vector to ensure the new function is changing the data.
    std::fill(y_h.begin(), y_h.end(), 0);
    
    start_time = std::chrono::system_clock::now();
    copy_usm_explicit(queue, x_h, y_h);

    // Like the buffer test, this is only included to be more fair to the
    // implicit USM tests.
    if (x_h != y_h) {
      std::cout << "ERROR: USM malloc_device execution failed." << std::endl;
      return 1;
    }
    end_time = std::chrono::system_clock::now();    
    std::chrono::duration<double> device_time = end_time - start_time;
    
    // END TEST USM EXPLICIT TRANSFERS USING MALLOC_DEVICE
    ////////////////////////////////////////////////////////////////////////////
    
    std::cout << "SUCCESS!" << std::endl
	      << "Buffers: " << buffer_time.count() << "s" << std::endl
	      << "USM malloc_shared: " << shared_time.count() << "s" << std::endl
      	      << "USM malloc_host: " << host_time.count() << "s" << std::endl
	      << "USM malloc_device: " << device_time.count() << "s" << std::endl;
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }
  
  return 0;
}
