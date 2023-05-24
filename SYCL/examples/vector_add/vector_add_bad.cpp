// Cale Woodward
// Greg Stitt
// University of Florida
//
// vector_add_bad.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   out[i] = in1[i] + in2[i];
//
// This example teaches the basics of SYCL, while including a common bug that we
// will fix in the next example.

#include <iostream>
#include <vector>

#include <CL/sycl.hpp>

const int VECTOR_SIZE = 1000;

class vector_add;

int main(int argc, char* argv[]) { 
  
  std::cout << "Performing vector addition...\n"
	    << "Vector size: " << VECTOR_SIZE << std::endl;

  // Declare the input and output vectors.
  // The _h suffix is used to signify that these variables are stored on the host.
  std::vector<int> in1_h(VECTOR_SIZE);
  std::vector<int> in2_h(VECTOR_SIZE);
  std::vector<int> out_h(VECTOR_SIZE);

  // Use another vector simply to verify functionality.
  std::vector<int> correct_out(VECTOR_SIZE);

  // Initialize vectors.
  for (size_t i=0; i < VECTOR_SIZE; i++) {
    in1_h[i] = i;
    in2_h[i] = i;
    out_h[i] = 0;
    correct_out[i] = i + i;
  }

  // Select a device to run the code and create a queue for sending commands.
  // Here we use the default_selector, which chooses a "default" device. The
  // default is usually a GPU if the host has access to one.  
  cl::sycl::queue queue(cl::sycl::default_selector_v);

  // The previous line is new to SYCL version 2023, so if you are using an older
  // version, you might get errors unless you do the following instead from the
  // 2020 specification. This technique is deprecated in 2023, so you will likely
  // get warnings using this older approach on newer tools.
  //cl::sycl::queue queue(cl::sycl::default_selector{});

  // Alternatively, you can separate the select and queue creation:
  // cl::sycl::default_selector selector;
  // cl::sycl::queue queue(selector);

  // Declare bufferes that handle transfers to/from the device(s).
  // The buffer class has 2 template parameters: type (int) and number of dimenstions (1)
  // Each buffer's constructor (the part in braces), takes a pointer to the host data
  // to attach to the buffer, and a "range", which is similar to an NDRAnge in OpenCL.
  // The range specifies the number of dimensions (<1>) and the number of elements in each
  // dimension, which in this case is the size of each vector.
  cl::sycl::buffer<int, 1> in1_buf {in1_h.data(), cl::sycl::range<1>(in1_h.size()) };
  cl::sycl::buffer<int, 1> in2_buf {in2_h.data(), cl::sycl::range<1>(in2_h.size()) };
  cl::sycl::buffer<int, 1> out_buf {out_h.data(), cl::sycl::range<1>(out_h.size()) };
    
  // Next, we tell the device what to do by sending it a function via the queue's
  // submit function. The submit method takes a single parameter, which is specified here
  // using a lambda (which is the common convention). The lambda function is passed a
  // single parameter called a "handler." In later examples, we will show how the handler
  // can be made implicit, but here we use it explicitly.
  queue.submit([&](cl::sycl::handler& handler) {

      // ALL CODE IN THIS SCOPE WILL EXECUTE ON THE SELECTED DEVICE
	
      // To allow the device to access the buffers, we need to create "accessors".
      // Accessors can be read_only, write_only, or read_write. Here, we only use
      // read_only for the inputs, and write_only for the outputs.
      // The _d suffix is a convention used to signify that the the corresponding
      // memory acceses are on the device, as opposed to the host.
      cl::sycl::accessor in1_d(in1_buf, handler, cl::sycl::read_only);
      cl::sycl::accessor in2_d(in2_buf, handler, cl::sycl::read_only);
      cl::sycl::accessor out_d(out_buf, handler, cl::sycl::write_only);

      // The following code "vectorizes" the original sequential loop.
      // The parallel_for has a template parameter specifying a kernel name, and two
      // normal parameters that specify the range and function to perform in parallel.
      // The template parameter can be optional in some situations, which are not
      // documented here.
      //
      // Like the NDRange in OpenCL, the range specifies the number and dimensionality
      // of work-items (threads). For this example, we use a single dimension of threads
      // with a total number of threads equal to the size of the vectors.
      // The final parameter is the function to execute in parallel, which is again
      // usually a lambda. The function here takes an "id" object, which allows each
      // individual thread/work-item to identify itself. Without this id, each thread
      // would not know what memory to access.       
      handler.parallel_for<class vector_add>(cl::sycl::range<1> { in1_h.size() }, [=](cl::sycl::id<1> i) {
	  out_d[i] = in1_d[i] + in2_d[i];
	});

    });

  // Before continuing with the host code, we have to wait until device finishes.
  // Otherwise, the results might not be completed.
  queue.wait(); 
  
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
