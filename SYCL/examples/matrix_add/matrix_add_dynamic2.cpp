// Greg Stitt
// University of Florida
//
// matrix_add_dynamic2.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code, which performs matrix addition:
//
// for (int i=0; i < NUM_ROWS; i++)
//   for (int j=0; j < NUM_COLS; j++) 
//     out[i][j] = in1[i][j] + in2[i][j];
//
// This implementations shows an alternative for dynamically
// sized arrays, but using a vector.

#include <iostream>
#include <vector>
#include <iomanip>
#include <cstdlib>
#include <string>

#include <CL/sycl.hpp>

class matrix_add;

void print_usage(const std::string &name) {

  std::cout << name << " num_rows num_cols (both must be positive)." << std::endl;
}

int main(int argc, char* argv[]) { 

  size_t num_rows;
  size_t num_cols;
  
  if (argc != 3) {
    print_usage(argv[0]);
    return 1;    
  }
  else {

    int rows = atoi(argv[1]);
    int cols = atoi(argv[2]);
    if (rows < 1 || cols < 1) {
      print_usage(argv[0]);
      return 1;
    }

    num_rows = rows;
    num_cols = cols;
  }

  // CHANGES FROM PREVIOUS EXAMPLE
  // In this example, we use vectors. We saw in a previous example
  // that vectors didn't work. However, that was because a vector
  // of vectors does not store all the vectors contiguously.
  // As long as we create a 1D vector that will store our 2D matrix,
  // it works perfectly fine.
  std::vector<int> in1_h(num_rows*num_cols);
  std::vector<int> in2_h(num_rows*num_cols);
  std::vector<int> out_h(num_rows*num_cols);
  std::vector<int> correct_out(num_rows*num_cols);
  
  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      in1_h[i*num_cols + j] = i;
      in2_h[i*num_cols + j] = j;
      out_h[i*num_cols + j] = 0;
      correct_out[i*num_cols + j] = i + j;
    }
  }

  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v);

    // CHANGES FROM PREVIOUS PREVIOUS
    // Since our matrices are now in a vector, we need to call .data() to get the int*.
    cl::sycl::buffer<int, 2> in1_buf(in1_h.data(), cl::sycl::range<2> {num_rows, num_cols} );
    cl::sycl::buffer<int, 2> in2_buf(in2_h.data(), cl::sycl::range<2> {num_rows, num_cols} );
    cl::sycl::buffer<int, 2> out_buf(out_h.data(), cl::sycl::range<2> {num_rows, num_cols} );
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor in1_d(in1_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor in2_d(in2_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor out_d(out_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class matrix_add>(cl::sycl::range<2> { num_rows, num_cols }, [=](cl::sycl::id<2> id) {
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
  
  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      std::cout << std::setw(5) << out_h[i*num_cols + j] << " ";
    }
    std::cout << std::endl;
  }

  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      if (out_h[i*num_cols + j] != correct_out[i*num_cols + j]) {
	std::cout << "ERROR: Execution failed." << std::endl;
	return 1;
      }
    }
  }
  
  std::cout << "SUCCESS!" << std::endl;
    
  return 0;
}
