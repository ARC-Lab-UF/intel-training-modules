// Greg Stitt
// University of Florida
//
// matrix_add_static2.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code, which performs matrix addition:
//
// for (int i=0; i < NUM_ROWS; i++)
//   for (int j=0; j < NUM_COLS; j++) 
//     out[i][j] = in1[i][j] + in2[i][j];
//
// This implementation shows an alternative correct way that uses
// C-style 2D arrays to ensure the matrices are stored sequentially.

#include <iostream>
#include <array>
#include <iomanip>

#include <CL/sycl.hpp>

const int NUM_ROWS = 10;
const int NUM_COLS = 5;

class matrix_add;

int main(int argc, char* argv[]) { 

  // CHANGES FROM PREVIOUS EXAMPLE
  // In this example, we use C-style 2D arrays, which are guaranteed
  // to be stored sequentially (in row-major order).
  int in1_h[NUM_ROWS][NUM_COLS];
  int in2_h[NUM_ROWS][NUM_COLS];
  int out_h[NUM_ROWS][NUM_COLS];
  int correct_out[NUM_ROWS][NUM_COLS];
  
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
    // Like the previous example, you might be tempted to do this. However this does
    // not work because the constructor is expecting an int* and int_h is an
    // int[NUM_ROWS][NUM_COLS] (basically a pointer to a pointer).
    /*cl::sycl::buffer<int, 2> in1_buf(in1_h, cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> in2_buf(in2_h, cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> out_buf(out_h, cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );*/
    
    // We know that the 2D array is stored sequentially in memory,
    // so we can again cast the int[NUM_ROWS][NUM_COLS] to an int*.
    cl::sycl::buffer<int, 2> in1_buf(reinterpret_cast<int*>(in1_h), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> in2_buf(reinterpret_cast<int*>(in2_h), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> out_buf(reinterpret_cast<int*>(out_h), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    
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
