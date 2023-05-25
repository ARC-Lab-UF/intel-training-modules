// Greg Stitt
// University of Florida
//
// matrix_add_static1.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code, which performs matrix addition:
//
// for (int i=0; i < NUM_ROWS; i++)
//   for (int j=0; j < NUM_COLS; j++) 
//     out[i][j] = in1[i][j] + in2[i][j];
//
// This implementation shows a correct way of replacing the vectors with
// arrays that guarantee the matrices are stored sequentially in memory.

#include <iostream>
#include <array>
#include <iomanip>

#include <CL/sycl.hpp>

const int NUM_ROWS = 10;
const int NUM_COLS = 5;

class matrix_add;

int main(int argc, char* argv[]) { 

  // CHANGES FROM PREVIOUS EXAMPLE
  // Here, we replace the dynamically allocated vectors with statically
  // allocated arrays that are guaranteed to store sequentiall in
  // memory (in row-major order).
  std::array<std::array<int, NUM_COLS>, NUM_ROWS> in1_h;
  std::array<std::array<int, NUM_COLS>, NUM_ROWS> in2_h;
  std::array<std::array<int, NUM_COLS>, NUM_ROWS> out_h;
  std::array<std::array<int, NUM_COLS>, NUM_ROWS> correct_out;
  
  for (size_t i=0; i < NUM_ROWS; i++) {
    for (size_t j=0; j < NUM_COLS; j++) {
      in1_h[i][j] = i;
      in2_h[i][j] = j;
      out_h[i][j] = 0;
      correct_out[i][j] = i + j;
    }
  }

  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v);

    // CHANGES FROM PREVIOUS EXAMPLE
    // It is likely tempting to use this code, since .data() returns a pointer to the
    // beginning of the 2D array, and we know that data is stored sequentially. However,
    // this will not compile becuase the constructor is expecting an int*. .data() returns
    // an array<int, NUM_COLS>* pointer. The compiler has no idea whether or not this is
    // a safe conversion, so it reports an error.
    /*cl::sycl::buffer<int, 2> in1_buf(in1_h.data(), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> in2_buf(in2_h.data(), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> out_buf(out_h.data(), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );*/
    
    // We know that the 2D array is stored sequentially in memory, so we can cast the the
    // array<int, NUM_COLS>* to an int*. Be vary careful with this of conversion because it
    // can lead to strange problems. 
    cl::sycl::buffer<int, 2> in1_buf(reinterpret_cast<int*>(in1_h.data()), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> in2_buf(reinterpret_cast<int*>(in2_h.data()), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> out_buf(reinterpret_cast<int*>(out_h.data()), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );

    // You could also accomplish the same thing with C-style casting, but that is not as safe
    // in general because the compiler doesn't apply any error checking.
    /*    cl::sycl::buffer<int, 2> in1_buf((int*) in1_h, cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> in2_buf((int*) in2_h, cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> out_buf((int*) out_h, cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );*/
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor in1_d(in1_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor in2_d(in2_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor out_d(out_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class matrix_add>(cl::sycl::range<2> { NUM_ROWS, NUM_COLS }, [=](cl::sycl::id<2> id) {
	    size_t x = id[0];
	    size_t y = id[1];
	    out_d[x][y] = in1_d[x][y] + in2_d[x][y];
	  });

      });

    queue.wait_and_throw();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }
  
  for (size_t i=0; i < NUM_ROWS; i++) {
    for (size_t j=0; j < NUM_COLS; j++) {
      std::cout << std::setw(5) << out_h[i][j] << " ";
    }
    std::cout << std::endl;
  }

  for (size_t i=0; i < NUM_ROWS; i++) {
    for (size_t j=0; j < NUM_COLS; j++) {
      if (out_h[i][j] != correct_out[i][j]) {
	std::cout << "ERROR: Execution failed." << std::endl;
	return 1;
      }
    }
  }
  
  std::cout << "SUCCESS!" << std::endl;
    
  return 0;
}
