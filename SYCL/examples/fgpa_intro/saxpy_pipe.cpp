// Greg Stitt
// University of Florida
//
// saxpy_pipe.cpp
//
// This SYCL program will create an FPGA implementation of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++)
//   z[i] = a * x[i] + y[i];
//
// In this example, we split the SAXPY computation across two
// kernels like we did in the previous saxpy_multi_kernel.cpp
// example.
//
// However, instead of using an extra vector to store the
// intermediate results, we now use pipes, which act as FIFOs
// between the kernels on the FPGAs. This FIFO functionality
// is critical because it:
//
// 1) enables "deep" parallelism where different kernels run at
//    the same time without waiting on each other. They instead
//    only wait on data, not completion.
// 2) minimizes transfer times. The intermediate storage in the
//    previous example required extra writes and reads from
//    global memory.
//
// We again use the fpga_emualtor selector instead of an actual FPGA.

#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <cmath>

#include <CL/sycl.hpp>
#include <sycl/ext/intel/fpga_extensions.hpp>

// Referencing a pipe requires a lot of code to the namespace and
// template parameters, so we use this "using" construct to shorten
// that code.
//
// ext::intel::pipe defines the pipe construct, where the first
// template parameter is a name for the pipe, the second is the
// type of data passed in the pipe, and the 3rd (optional)
// parameter is the depth of the pipe. Conceptually, this is
// identical to a FIFO with depth 4 that stores floats.
//
// NOTE: there is also a sycl::pipe<>. I don't know the exact
// differences, but I suspect to use Intel FPGAs, you would need
// their custom pipe extension. Either works with the fpga emulator,
// but I have not tested or profiled actual FPGA execution.

using saxpy_pipe = cl::sycl::ext::intel::pipe<class SaxpyPipe, float, 16>;

const int VECTOR_SIZE = 1000;

const float ALLOWABLE_ERROR = 0.000001;
bool are_floats_equal(float a, float b, float abs_tol=ALLOWABLE_ERROR, float rel_tol=ALLOWABLE_ERROR) {

  float diff = fabs(a-b);
  return (diff <= abs_tol || diff <= rel_tol * fmax(fabs(a), fabs(b)));
}


class saxpy;

int main(int argc, char* argv[]) { 

  float a;
  // CHANGES FROM PREVIOUS EXAMPLES
  // Note that we no longer need the a_times_x[] vector since instead
  // of using temporary storage, we are sending those values
  // directly between kernels using pipes.
  std::vector<float> x_h(VECTOR_SIZE);
  std::vector<float> y_h(VECTOR_SIZE);
  std::vector<float> z_h(VECTOR_SIZE);
  std::vector<float> correct_out(VECTOR_SIZE);
  
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_real_distribution<> dist(0, 100);
  
  a = dist(gen);
  for (size_t i=0; i < VECTOR_SIZE; i++) {
    x_h[i] = dist(gen);
    y_h[i] = dist(gen);
    z_h[i] = 0;
    correct_out[i] = a * x_h[i] + y_h[i];
  }

  try {
    cl::sycl::queue queue(cl::sycl::ext::intel::fpga_emulator_selector_v);

    // CHANGES FROM PREVIOUS EXAMPLES.
    // We no longer need an a_times_x buffer any more due to the pipes.
    cl::sycl::buffer<float, 1> x_buf {x_h.data(), cl::sycl::range<1>(x_h.size()) };
    cl::sycl::buffer<float, 1> y_buf {y_h.data(), cl::sycl::range<1>(y_h.size()) };
    cl::sycl::buffer<float, 1> z_buf {z_h.data(), cl::sycl::range<1>(z_h.size()) };

    // CHANGES FROM PREVIOUS EXAMPLES.
    // In the first kernel, we still do a * x[i], but using a single_task to create a
    // pipeline. Instead of storing the result into the temporary buffer a_times_x, we
    // directly send it to the other kernel instances using the pipe, which is
    // essentially a FIFO that enables "deep" parallelism.
    queue.submit([&](cl::sycl::handler& handler) {

	// We only need the read accessor now.
	cl::sycl::accessor x_d(x_buf, handler, cl::sycl::read_only);

	handler.single_task<class x_times_a>([=]() {
	    for (size_t i=0; i < VECTOR_SIZE; i++) {
	      // CHANGES FROM PREVIOUS EXAMPLES
	      // Write the output of each iteration to the pipe/FIFO, which
	      // will be read by the other kernel.
	      saxpy_pipe::write(a * x_d[i]);
	    }
	  });
      });

    queue.submit([&](cl::sycl::handler& handler) {
	
	// CHANGES FROM PREVIOUS EXAMPLES
	// We no longer need the a_times_x accessor here because of the pipe.
	cl::sycl::accessor y_d(y_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor z_d(z_buf, handler, cl::sycl::write_only);

	handler.single_task<class plus_y>([=]() {

	    for (size_t i=0; i < VECTOR_SIZE; i++) {
	      // CHANGES FROM PREVIOUS EXAMPLES
	      // Read from the pipe to get the a_times_x value for
	      // each iteration, and then add y_d[i].
	      float a_times_x = saxpy_pipe::read();
	      z_d[i] = a_times_x + y_d[i];
	    }
	  });
      });
    
    queue.wait();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }
  
  for (int i=0; i < VECTOR_SIZE; i++) {    
    if (!are_floats_equal(z_h[i], correct_out[i])) {\
      std::cout << a << " * " << x_h[i] << " + " << y_h[i] << " = " << z_h[i] << "\n";      
      std::cout << std::setprecision(12)
		<< "ERROR: Execution failed. Expected output of " << correct_out[i]
		<< " instead of " << z_h[i] << std::endl;
      return 1;
    }    
  }
  
  std::cout << "SUCCESS!" << std::endl;
    
  return 0;
}
