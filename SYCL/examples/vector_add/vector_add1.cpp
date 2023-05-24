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
// In this modified version of the code, we fix the bug from the previous version.

#include <CL/sycl.hpp>

#include <iostream>
#include <vector>

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

  cl::sycl::queue queue(cl::sycl::default_selector_v);

  // CHANGES FROM PREVIOUS EXAMPLE
  // To fix the bug from the previous version where the output was always 0,
  // we can add new scope for all the device code. It will be explained in detail later,
  // but the previous problem was that the output was never transferred from device memory
  // back to the host. By putting the device code in a separate scope, all objects are
  // "destructed" at the end of the scope, which for out_buf causes the host to transfer
  // the outputs back from the device. There are other methods we could have used,
  // but using a separate scope is common, especially since that scope is usually created
  // by a try-catch, as we will see in the next example.
  {
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
  
  // CHANGES FROM PREVIOUS EXAMPLE
  // As an alternative to adding a new scope to ensure the output is transferred
  // back to the host, we can explicitly transfer the outputs with the following
  // code, where the host requests read access to the output buffer.
  // 
  // out_buf.get_access<cl::sycl::access::mode::read>();
    
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
