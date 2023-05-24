// Cale Woodward
// Greg Stitt
// University of Florida
//
// vector_add.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   out[i] = in1[i] + in2[i];
//
// In this modified version of the code, we add exception handling to catch
// "synchronous" errors, which are errors that occur on the host. Catching errors
// that occur on the device will be explained in a later example.

#include <iostream>
#include <vector>

#include <CL/sycl.hpp>

const int VECTOR_SIZE = 1000;

class vector_add;

int main(int argc, char* argv[]) { 
  
  std::cout << "Performing vector addition...\n"
	    << "Vector size: " << VECTOR_SIZE << std::endl;

  std::vector<int> in1_h(VECTOR_SIZE);
  std::vector<int> in2_h(VECTOR_SIZE);
  std::vector<int> out_h(VECTOR_SIZE);
  std::vector<int> correct_out(VECTOR_SIZE);

  for (size_t i=0; i < VECTOR_SIZE; i++) {
    in1_h[i] = i;
    in2_h[i] = i;
    out_h[i] = 0;
    correct_out[i] = i + i;
  }

  // CHANGES FROM PREVIOUS EXAMPLE
  // Instead of just creating a new scope, it is usually a good idea to enclose the
  // device code in a try block to catch exceptions. This also creates a new scope
  // while enabling exception handling. It is important to understand that this try
  // block will only detect exceptions that occur on the host (i.e. synchronous errors).
  // To catch errors that occur during device execution (i.e. asynchronous errors),
  // we need additional code that will be explained in a later example.
  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v);
    
    cl::sycl::buffer<int, 1> in1_buf {in1_h.data(), cl::sycl::range<1>(in1_h.size()) };
    cl::sycl::buffer<int, 1> in2_buf {in2_h.data(), cl::sycl::range<1>(in2_h.size()) };
    cl::sycl::buffer<int, 1> out_buf {out_h.data(), cl::sycl::range<1>(out_h.size()) };
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor in1_d(in1_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor in2_d(in2_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor out_d(out_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class vector_add>(cl::sycl::range<1> { in1_h.size() }, [=](cl::sycl::id<1> i) {
	    out_d[i] = in1_d[i] + in2_d[i];
	  });

      });

    queue.wait();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }
  
  std::cout << "Operation complete:\n"
	    << "[" << in1_h[0] << "] + [" << in2_h[0] << "] = [" << out_h[0] << "]\n"
	    << "[" << in1_h[1] << "] + [" << in2_h[1] << "] = [" << out_h[1] << "]\n"
	    << "...\n"
	    << "[" << in1_h[VECTOR_SIZE - 1] << "] + [" << in2_h[VECTOR_SIZE - 1] << "] = [" << out_h[VECTOR_SIZE - 1] << "]\n"
	    << std::endl;

  if (out_h == correct_out) {
    std::cout << "SUCCESS!" << std::endl;
  }
  else {
    std::cout << "ERROR: Execution failed." << std::endl;
  }
  
  return 0;
}
