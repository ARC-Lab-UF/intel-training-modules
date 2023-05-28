// Greg Stitt
// University of Florida
//
// usm_vs_buffers2.cpp
//
// This example modifies usm_vs_buffers.cpp by evaluating situations where
// not the entire array needs to be read back by the host. This happens
// frequently in reduction problems. For example, accumulation of 1B values
// only requires 1 value to be read back. For the methods with implicit
// transfers, it is important to understand if unnecessary data are being
// transferred, because those transfers are very expensive.
//
// In this example, we artificially modify the previous code by only
// reading back the first output and then evaluate the reduction in
// execution time.
//
// When running on the DevCloud with 1B inputs, these were the execution times.
//
// Buffers: 2.54154s             (was 2.873s, 11.5% reduction)
// USM malloc_shared: 0.481512s  (was 0.798s, 39.7% reduction)
// USM malloc_host: 0.483185s    (was 0.802s, 39.7% reduction)
// USM malloc_device: 2.01796s   (was 2.642s, 23.6% reduction)
//
// Based on these results, buffers were the least effective way of transferring
// only the data that is needed. This makes sense because the buffer's destructor
// transfers data from the device to the host regardless of whether or not it is used.
//
// Both implicit modes (shared and host) showed the biggest percentage improvement,
// which was slightly unexpected since the explicit methods (device) is guaranteed
// to transfer a single value.
//
// Again, results may vary for different compilers and devices.

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

  // CHANGES FROM PREVIOUS VERSION
  // Here, we explicitly only copy back one output to compare with the other methods.
  queue.memcpy(y_h.data(), y_d, sizeof(int));
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

    // CHANGE FROM PREVIOUS VERSION
    // We explicitly only compare one output in the hope that only one value
    // will be read from the device.    
    if (x_h[0] != y_h[0]) {
      std::cout << "ERROR: buffer execution failed." << std::endl;
      return 1;
    }
    end_time = std::chrono::system_clock::now();
    std::chrono::duration<double> buffer_time = end_time - start_time;

    // END TEST BUFFER/ACCESSOR METHOD
    ////////////////////////////////////////////////////////////////////////////

    
    ////////////////////////////////////////////////////////////////////////////
    // BEGIN TEST USM IMPLICIT TRANSFERS USING MALLOC_SHARED   
       
    int *x_usm_shared = cl::sycl::malloc_shared<int>(vector_size, queue);
    int *y_usm_shared = cl::sycl::malloc_shared<int>(vector_size, queue);
    memset(y_usm_shared, 0, sizeof(int) * vector_size);
    
    start_time = std::chrono::system_clock::now();

    for (size_t i=0; i < vector_size; i++)
      x_usm_shared[i] = x_h[i];      
    
    copy_usm_implicit(queue, x_usm_shared, y_usm_shared, vector_size);

    // CHANGE FROM PREVIOUS VERSION
    // Again, only compare one value in the hope that only one value is
    // transferred from the device.
    if (memcmp(x_usm_shared, y_usm_shared, sizeof(int) * 1)) {
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
    if (memcmp(x_usm_host, y_usm_host, sizeof(int) * 1)) {
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

    std::fill(y_h.begin(), y_h.end(), 0);
    
    start_time = std::chrono::system_clock::now();
    copy_usm_explicit(queue, x_h, y_h);

    if (x_h[0] != y_h[0]) {
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
